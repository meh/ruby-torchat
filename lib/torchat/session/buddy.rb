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

	attr_reader   :session, :id, :address, :avatar, :client, :tries, :last_try
	attr_writer   :status
	attr_accessor :name, :description, :alias, :last_received

	def port; 11009; end

	def initialize (session, id, incoming = nil, outgoing = nil)
		unless Tor.valid_id?(id)
			raise ArgumentError, "#{id} is an invalid onion id"
		end

		@session  = session
		@id       = id[/^(.*?)(\.onion)?$/, 1]
		@address  = "#{@id}.onion"
		@avatar   = Avatar.new
		@client   = Client.new
		@supports = []

		@tries = 0

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
		session.on what do |e|
			block.call e if e.buddy == self
		end
	end

	alias when on

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
	def typing!;     @typing = :start;     end
	def thinking!;   @typing = :thinking;  end
	def not_typing!; @typing = :stop;      end

	def send_packet (*args)
		raise 'you cannot send packets yet' unless has_outgoing?

		@outgoing.send_packet *args
	end

	def send_packet! (*args)
		raise 'you cannot send packets yet' unless has_outgoing?

		@outgoing.send_packet! *args
	end

	def send_message (text)
		send_packet :message, text
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

		session.fire :failed_connection, buddy: self
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

		session.fire :connection, buddy: self
	end

	def verified?; @verified; end

	def verified (incoming)
		return if verified?

		@verified = true

		own! incoming

		session.fire :verification, buddy: self

		@outgoing.verification_completed
		@incoming.verification_completed
	end

	def disconnect
		return if disconnected?

		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		@outgoing = @incoming = nil

		disconnected
	end

	def disconnected?; !@connected; end

	def disconnected
		return if disconnected?

		@last_received = @verified = @ready = @connecting = @connected = false

		disconnect

		session.fire :disconnection, buddy: self
	end

	def inspect
		"#<Torchat::Buddy(#{id})#{": #{name}#{", #{description}" if description}" if name}>"
	end
end

end; end
