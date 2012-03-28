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

class Outgoing < EventMachine::Protocols::LineAndTextProtocol
	attr_accessor :owner

	def post_init
		@delayed = []
	end

	def connection_completed
		socksify("#{@owner.address}.onion", @owner.port) do
			@owner.connected
		end
	end

	def authentication_completed
		@delayed.each { |p| send_packet! p }
		@delayed = false
	end

	def receive_line (line)
		packet = Protocol::Packet.from(@owner, line.chomp)
		
		return unless packet.type.to_s.start_with 'file'

		@owner.server.received packet
	end

	def send_packet (*args)
		if @delayed
			@delayed << args
		else
			send_packet! *args
		end
	end

	def send_packet! (*args)
		send_data(if args.first.is_a? Symbol
			Protocol::Packet[args.shift].new(*args)
		else
			args.first
		end.pack)
	end

	def unbind
		@owner.disconnected
	end
end

end; end
