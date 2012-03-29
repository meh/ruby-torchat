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

require 'torchat/avatar'

require 'torchat/session/incoming'
require 'torchat/session/outgoing'

class Torchat; class Session

class Buddy
	attr_reader   :session, :id, :address, :avatar
	attr_accessor :name, :description

	def port; 11009; end

	def initialize (session, address, incoming = nil, outgoing = nil)
		unless Protocol.valid_address?(address)
			raise ArgumentError, "#{address} is an invalid onion id"
		end

		@session = session
		@id      = address[/^(.*?)(\.onion)?$/, 1]
		@address = "#{@id}.onion"
		@avatar  = Avatar.new

		own! incoming
		own! outgoing

		connect unless @outgoing
	end

	def own! (what)
		if what.is_a? Incoming
			@incoming = what
		elsif what.is_a? Outgoing
			@outgoing = what
		end

		@incoming.owner = self if @incoming
		@outgoing.owner = self if @outgoing
	end

	def pinged?; @pinged;         end
	def ping!;   @pinged = true;  end
	def pong!;   @pinged = false; end

	def send_packet (*args)
		raise 'you cannot send packets yet' unless @outgoing

		@outgoing.send_packet *args
	end

	def send_packet! (*args)
		raise 'you cannot send packets yet' unless @outgoing

		@outgoing.send_packet! *args
	end

	def send_message (text)
		send_packet :message, text
	end

	def connecting?; @connecting; end

	def connect
		return if connecting?

		@connecting = true

		EM.connect session.tor.host, session.tor.port, Outgoing do |outgoing|
			own! outgoing

			outgoing.instance_variable_set :@session, session

			session.fire :outgoing, outgoing
		end
	end

	def connected?; @connected; end

	def connected
		return if connected?

		@connected = true

		send_packet! :ping, session.address

		ping!

		session.fire :connection, self
	end

	def verified?; @verified; end

	def verified
		return if verified?

		@verified = true

		@outgoing.verification_completed

		session.buddies << self

		session.fire :verification, self
	end

	def disconnect
		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		session.buddies.delete(session.buddies.key(self))

		@outgoing = @incoming = nil

		disconnected
	end

	def disconnected?; @disconnected; end

	def disconnected
		return if disconnected?

		@disconnected = true

		disconnect

		session.fire :disconnection, self
	end

	def inspect
		"#<Torchat::Buddy(#{id})#{": #{name}#{", #{description}" if description}" if name}>"
	end
end

end; end
