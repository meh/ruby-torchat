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
	attr_reader   :server, :address
	attr_accessor :alias, :name, :description

	def port; 11009; end

	def initialize (server, address, incoming = nil, outgoing = nil)
		unless Protocol.valid_address?(address)
			raise ArgumentError, "#{address} is an invalid onion id"
		end

		@server  = server
		@address = address[/^(.*?)(\.onion)?$/, 1]

		@incoming = incoming
		@outgoing = outgoing

		connect! unless @outgoing

		own!
	end

	def own!
		@incoming.owner = self if @incoming
		@outgoing.owner = self if @outgoing
	end

	def connect!
		EM.connect server.tor.host, server.tor.port, Outgoing do |outgoing|
			@outgoing = outgoing
		end

		own!
	end

	def send_packet (packet)
		raise 'you cannot send packets yet' unless @outgoing

		@outgoing.send_packet
	end

	def disconnect
		@incoming.close_connection_after_writing if @incoming
		@outgoing.close_connection_after_writing if @outgoing

		@outgoing = @incoming = nil
	end
end

end; end
