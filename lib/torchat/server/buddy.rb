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

require 'torchat/server/incoming'
require 'torchat/server/outgoing'

class Torchat; class Server

class Buddy
	attr_reader   :server, :id, :address
	attr_accessor :name, :description

	def port; 11009; end

	def initialize (server, address, incoming = nil, outgoing = nil)
		unless Protocol.valid_address?(address)
			raise ArgumentError, "#{address} is an invalid onion id"
		end

		@server  = server
		@id      = address[/^(.*?)(\.onion)?$/, 1]
		@address = "#{@id}.onion"

		@incoming = incoming
		@outgoing = outgoing

		connect unless @outgoing

		own!
	end

	def own!
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

	def connect
		EM.connect server.tor.host, server.tor.port, Outgoing do |outgoing|
			@outgoing = outgoing
		end

		own!
	end

	def connected?; @connected; end

	def connected
		return if connected?

		@connected = true

		send_packet! :ping, server.address

		ping!

		server.fire :connection, self
	end

	def verified?; @verified; end

	def verified
		return if verified?

		@verified = true

		@outgoing.verification_completed

		server.buddies << self

		send_packet :version, Torchat.version
		send_packet :client,  'ruby-torchat'
		send_packet :status,  :available

		server.fire :verification, self
	end

	def disconnect
		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		server.buddies.delete(server.buddies.key(self))

		@outgoing = @incoming = nil

		disconnected
	end

	def disconnected?; @disconnected; end

	def disconnected
		return if disconnected?

		@disconnected = true

		disconnect

		server.fire :disconnection, self
	end

	def inspect
		"#<Torchat::Buddy(#{id})#{": #{name}#{", #{description}" if description}" if name}>"
	end
end

end; end
