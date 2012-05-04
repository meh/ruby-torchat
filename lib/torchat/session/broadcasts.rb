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

require 'torchat/session/broadcast/message'

class Torchat; class Session

class Broadcasts < Array
	attr_reader :session

	def initialize (session)
		@session = session
	end

	def send_message (message)
		received(message)
	end

	def received? (message)
		any? { |m| m.to_s == message }
	end

	def received (message)
		return if received? message

		Broadcast::Message.parse(message).tap {|message|
			push message

			session.buddies.each_online {|id, buddy|
				if buddy.supports? :broadcast
					buddy.send_packet [:broadcast, :message], message.to_s
				end
			}

			session.fire :broadcast, message: message
		}
	end

	def flush! (time)
		delete_if {|message|
			(Time.now.to_i - message.at.to_i) > time
		}
	end
end

end; end
