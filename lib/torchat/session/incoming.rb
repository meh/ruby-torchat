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

class Torchat; class Session

class Incoming < EventMachine::Protocols::LineAndTextProtocol
	attr_accessor :owner

	def receive_line (line)
		packet = begin
			Protocol::Packet.from(@owner, line.chomp)
		rescue => e
			Torchat.debug line.inspect
			Torchat.debug e

			return
		end

		Torchat.debug "<< #{@owner ? @owner.id : 'unknown'} #{packet.inspect}", level: 2

		if packet.type == :ping
			if !packet.valid? || packet.address == @session.address || @last_ping_address && packet.address != @last_ping_address
				close_connection_after_writing
				
				return
			end

			@last_ping_address = packet.address

			if buddy = @session.buddies[packet.address]
				buddy.own! self
			end

			if @owner
				if @outgoing_was_here
					@owner.send_packet :pong, packet.cookie
				else
					@owner.send_packet! :pong, packet.cookie
				end
			else
				if buddy = @session.buddies[packet.address] && buddy.online?
					close_connection_after_writing
					
					return
				end

				@outgoing_was_here = true

				Buddy.new(@session, packet.address, self).tap {|buddy|
					buddy.connect
					buddy.send_packet :pong, packet.cookie
				}
			end
		elsif packet.type == :pong
			return unless @owner && @owner.pinged?

			unless @owner.verified?
				@owner.verified
			end

			@owner.pong!
		else
			@owner.session.received packet if packet && @owner && @owner.connected?
		end
	end

	def unbind
		if error?
			Torchat.debug "errno #{EM.report_connection_error_status(@signature)}", level: 2
		end

		@owner.disconnect if @owner
	end
end

end; end
