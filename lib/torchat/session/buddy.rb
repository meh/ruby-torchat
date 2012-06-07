#--
# Copyleft meh. [http://meh.paranoid.pk | meh@paranoici.org]
#
# This file is part of torchat for ruby.
#
# torchat for ruby is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# torchat for ruby is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with torchat for ruby. If not, see <http://www.gnu.org/licenses/>.
#++

require 'eventmachine'

require 'torchat/session/incoming'
require 'torchat/session/outgoing'

class Torchat; class Session

class Buddy
	class Avatar
		attr_writer :rgb, :alpha

		def to_image
			return unless @rgb

			require 'chunky_png'

			ChunkyPNG::Image.new(64, 64, ChunkyPNG::Color::TRANSPARENT).tap {|image|
				@rgb.bytes.each_slice(3).with_index {|(r, g, b), index|
					x, y = index % 64, index / 64
					
					image[x, y] = if @alpha
						ChunkyPNG::Color.rgba(r, g, b, @alpha[index])
					else
						ChunkyPNG::Color.rgb(r, g, b)
					end
				}
			}
		end
	end

	Client = Struct.new(:name, :version)

	attr_reader   :session, :id, :address, :avatar, :client, :tries, :last_try, :messages, :group_chats
	attr_writer   :status
	attr_accessor :name, :description, :alias, :last_received

	def port; 11009; end

	def initialize (session, id, incoming = nil, outgoing = nil)
		unless Torchat.valid_id?(id)
			raise ArgumentError, "#{id} is an invalid onion id"
		end

		@session     = session
		@id          = id[/^(.*?)(\.onion)?$/, 1]
		@address     = "#{@id}.onion"
		@callbacks   = []
		@avatar      = Avatar.new
		@client      = Client.new
		@supports    = []
		@messages    = []
		@group_chats = JoinedGroupChats.new(self)
		@tries       = 0
		@last_try    = nil
		@typing      = :stop

		own! incoming
		own! outgoing
	end

	def supports (*what)
		@supports.concat(what).uniq!
	end

	def supports? (what)
		@supports.include?(what.to_sym.downcase)
	end

	def status
		online? ? @status : :offline
	end

	def on (what, &block)
		removable = session.on what do |e|
			block.call e if e.buddy == self
		end

		@callbacks << removable

		removable
	end

	def on_packet (name = nil)
		removable = if name
			on :packet do |e|
				block.call e if e.packet.type == name
			end
		else
			on :packet, &block
		end

		@callbacks << removable

		removable
	end

	def remove_callbacks
		@callbacks.each(&:remove!).clear
	end

	def has_incoming?
		!!@incoming
	end

	def has_outgoing?
		!!@outgoing
	end

	def own! (what)
		if what.is_a? Incoming
			@incoming = what
		elsif what.is_a? Outgoing
			@outgoing = what
		end

		@incoming.owner = self if has_incoming?
		@outgoing.owner = self if has_outgoing?
	end

	def pinged?;  @pinged;         end
	def ping!(c); @pinged = c;  end
	def pong!;    @pinged = false; end

	def removed?; @removed;        end
	def remove!;  @removed = true; end

	def blocked?; @blocked;         end
	def allowed?; !@blocked;        end

	def block!
		@blocked = true

		disconnect
	end

	def allow!
		@blocked = false

		connect
	end

	def temporary?; @temporary;         end
	def permanent?; !@temporary;        end
	def temporary!; @temporary = true;  end
	def permanent!; @temporary = false; end

	def typing?;     @typing == :start;    end
	def thinking?;   @typing == :thinking; end
	def not_typing?; @typing == :stop;     end

	def typing!
		return if typing?

		@typing = :start

		session.fire :typing, buddy: self, mode: :start
	end

	def thinking!
		return if thinking?

		@typing = :thinking

		session.fire :typing, buddy: self, mode: :thinking
	end

	def not_typing!
		return if not_typing?

		@typing = :stop

		session.fire :typing, buddy: self, mode: :stop
	end

	def send_packet (*args)
		raise 'you cannot send packets yet' unless has_outgoing?

		@outgoing.send_packet *args
	end

	def send_packet! (*args)
		raise 'you cannot send packets yet' unless has_outgoing?

		@outgoing.send_packet! *args
	end

	def send_message (text)
		if offline?
			@messages << text

			unless @messages.empty?
				on :ready do |e|
					until @messages.empty?
						break if offline?

						send_message "[delayed] #{@messages.shift}"
					end

					if @messages.empty?
						e.remove!
					end
				end
			end
		else
			send_packet :message, text
		end
	end

	def send_file (path)
		session.file_transfers.send_file(self, path)
	end

	def send_blob (data)
		session.file_transfers.send_blob(self, data)
	end

	def send_typing (mode)
		return unless supports? :typing

		send_packet "typing_#{mode}"
	end

	def online?; connected?; end
	def offline?; !online?;  end

	def ready?; @ready;        end
	def ready!; @ready = true; end

	def failed!
		@connecting = false

		session.fire :connect_failure, buddy: self
	end

	def connecting?; @connecting; end

	def connect
		return if connecting? || connected? || blocked?

		@connecting  = true
		@tries      += 1
		@last_try    = Time.new

		EM.connect session.tor.host, session.tor.port, Outgoing do |outgoing|
			outgoing.instance_variable_set :@session, session

			own! outgoing
		end
	end

	def connected?; @connected; end

	def connected
		return if connected?

		@last_received = Protocol.packet :status, :available

		@connecting = false
		@connected  = true

		@tries    = 0
		@last_try = nil

		ping! send_packet!(:ping, session.address).cookie

		session.fire :connect, buddy: self
	end

	def verified?; @verified; end

	def verified (incoming)
		return if verified?

		@verified = true

		own! incoming

		session.fire :verify, buddy: self

		@outgoing.verification_completed
		@incoming.verification_completed
	end

	def disconnect
		return if disconnected?

		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		@outgoing = nil
		@incoming = nil

		disconnected
	end

	def disconnected?; !@connected; end

	def disconnected
		return if disconnected?

		session.fire :disconnect, buddy: self

		@verified      = false
		@ready         = false
		@connecting    = false
		@connected     = false
		@tries         = 0
		@last_received = nil

		@group_chats.clear

		disconnect
	end

	def inspect
		"#<Torchat::Buddy(#{id})#{": #{name}#{", #{description}" if description}" if name}>"
	end
end

end; end

require 'torchat/session/buddy/joined_group_chats'
