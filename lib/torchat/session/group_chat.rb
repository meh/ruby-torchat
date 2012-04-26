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

class GroupChat
	attr_reader :session, :id, :modes, :participants

	def initialize (session, id, *modes)
		@session = session
		@id      = id
		@modes   = modes.flatten.uniq.compact.map(&:to_sym)

		@participants = []
	end

	def invited!; @invited = true; end
	def invited?; @invited;        end

	def invite (buddy)

	end

	def delete (buddy)
		@participants.delete(session.buddies[buddy])
	end

	def leave
		participants.each {|buddy|
			buddy.send_packet [:groupchat, :leave], id
		}

		session.group_chats.left id
	end

	def send_message (message)
		@participants.each {|buddy|
			buddy.send_packet [:groupchat, :message], id, message
		}
	end
end

end; end
