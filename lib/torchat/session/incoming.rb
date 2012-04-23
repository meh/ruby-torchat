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

	def post_init
		@delayed = []
	end

	def receive_line (line)
		packet = begin
			Protocol.unpack(line.chomp, @owner)
		rescue => e
			if e.is_a?(ArgumentError) && e.message.end_with?('packet unknown')
				@session.fire :unknown do
					line  line
					buddy @owner if @owner
				end
			else
				Torchat.debug line.inspect
				Torchat.debug e
			end

			return
		end

		if packet.type == :ping
			Torchat.debug "ping incoming from claimed #{packet.id}", level: 2

			if @session.offline?
				close_connection_after_writing

				Torchat.debug 'we are offline, kill the connection'

				return
			end

			if !packet.valid? || packet.id == @session.id || @last_ping && packet.id != @last_ping.id
				close_connection_after_writing

				Torchat.debug 'invalid packet or DoS attempt'

				return
			end

			@last_ping = packet

			if buddy = @session.buddies[packet.id]
				if buddy.blocked?
					close_connection_after_writing

					Torchat.debug "#{buddy.id} is blocked"

					return
				end

				if buddy.has_incoming? && buddy.instance_variable_get(:@incoming) != self
					close_connection_after_writing

					Torchat.debug "#{buddy.id} already has an incoming connection"

					return
				end
			end

			if @owner
				@owner.send_packet :pong, packet.cookie
			else
				if buddy
					buddy.last_received = packet

					buddy.connect

					if buddy.connected?
						buddy.send_packet! :pong, packet.cookie
					else
						buddy.send_packet :pong, packet.cookie
					end
				else
					@temp_buddy = Buddy.new(@session, packet.id, self)

					@temp_buddy.last_received = packet

					@temp_buddy.connect
					@temp_buddy.send_packet :pong, packet.cookie
				end
			end
		elsif packet.type == :pong
			Torchat.debug "pong came with #{packet.cookie}", level: 2

			unless buddy = (@session.buddies[@last_ping.id] || @temp_buddy) || !buddy.pinged?
				close_connection_after_writing

				Torchat.debug 'pong received without a ping'

				return
			end

			if buddy.blocked?
				close_connection_after_writing

				Torchat.debug "#{buddy.id} is blocked."

				return
			end

			buddy.last_received = packet

			return unless @last_ping

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
			unless @owner
				if @last_ping
					@delayed << packet
				else
					close_connection_after_writing

					Torchat.debug 'someone sent a packet before the handshake'
					Torchat.debug "the packet was #{packet.inspect}", level: 2
				end

				return
			end

			Torchat.debug "<< #{@owner ? @owner.id : 'unknown'} #{packet.inspect}", level: 2

			@owner.last_received = packet

			@owner.session.received packet
		end
	rescue => e
		Torchat.debug e
	end

	def verification_completed
		@delayed.each {|packet|
			packet.from = @owner

			@owner.session.received packet
		}

		@delayed = nil
	end

	def unbind
		if error?
			Torchat.debug "errno #{EM.report_connection_error_status(@signature)}", level: 2
		end

		@owner.disconnect if @owner
	end
end

end; end
