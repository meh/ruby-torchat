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
		return if @session.offline?

		packet = begin
			Protocol::Packet.from(@owner, line.chomp)
		rescue => e
			Torchat.debug line.inspect
			Torchat.debug e

			return
		end

		@owner.last_action = packet if @owner

		if packet.type == :ping
			Torchat.debug "ping incoming from claimed #{packet.id}", level: 2

			if !packet.valid? || packet.address == @session.address || @last_ping && packet.address != @last_ping.address
				close_connection_after_writing

				Torchat.debug 'invalid packet or DoS attempt'

				return
			end

			@last_ping = packet

			if (buddy = @session.buddies[packet.address]) && buddy.has_incoming?
				close_connection_after_writing

				Torchat.debug "#{buddy.id} already has an incoming connection"

				return
			end

			if @owner
				@owner.send_packet :pong, packet.cookie
			else
				if buddy
					buddy.connect

					if buddy.connected?
						buddy.send_packet! :pong, packet.cookie
					else
						buddy.send_packet :pong, packet.cookie
					end
				else
					@temp_buddy = Buddy.new(@session, packet.address, self)
					@temp_buddy.connect
					@temp_buddy.send_packet :pong, packet.cookie
				end
			end
		elsif packet.type == :pong
			Torchat.debug "pong came with #{packet.cookie}", level: 2

			return unless @last_ping && buddy = @session.buddies[@last_ping.address] || @temp_buddy

			if packet.cookie != buddy.pinged?
				close_connection_after_writing

				Torchat.debug "#{packet.from.id} pong with wrong cookie"

				return
			end

			unless buddy.verified?
				buddy.verified self
			end

			buddy.pong!
		else
			Torchat.debug "<< #{@owner ? @owner.id : 'unknown'} #{packet.inspect}", level: 2

			@owner.session.received packet if packet && @owner && @owner.connected?
		end
	rescue => e
		Torchat.debug e
	end

	def unbind
		if error?
			Torchat.debug "errno #{EM.report_connection_error_status(@signature)}", level: 2
		end

		@owner.disconnect if @owner
	end
end

end; end
