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

class Torchat; class Server

class Incoming < EventMachine::Protocols::LineAndTextProtocol
	attr_accessor :owner

	def receive_line (line)
		packet = Protocol::Packet.from(@owner, line.chomp) rescue nil

		if packet.type == :ping || packet.type == :pong
			if packet.type == :ping && packet.valid?
				if @last_ping_address && packet.address != @last_ping_address
					close_connection_after_writing and return
				end

				@last_ping_address = packet.address

				if @owner
					@owner.send_packet :pong, packet.cookie
				else
					Buddy.new(@server, packet.address, self)
				end
			else
				return unless @owner && @owner.pinged?

				unless @owner.authenticated?
					@owner.authenticated
				end

				@owner.pong!
			end
		else
			@owner.server.received packet if packet && @owner && @owner.connected?
		end
	end

	def unbind
		@owner.disconnected if @owner
	end
end

end; end
