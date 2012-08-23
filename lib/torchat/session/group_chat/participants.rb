#--
# Copyleft meh. [http://meh.schizofreni.co | meh@schizofreni.co]
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

require 'torchat/session/group_chat/participant'

class Torchat; class Session; class GroupChat

class Participants < Hash
	attr_reader :group_chat

	def initialize (group_chat)
		@group_chat = group_chat
	end

	def add (id, invited_by = nil)
		return if has_key? Torchat.normalize_id(id)

		if buddy = group_chat.session.buddies[id]
			buddy.group_chats.add group_chat

			self[buddy.id] = Participant.new(buddy, invited_by)
		end
	end

	def delete (id)
		super(Torchat.normalize_id(id))

		if buddy = group_chat.session.buddies[id]
			buddy.group_chats.delete(group_chat)
		end
	end

	private :[]=
end

end; end; end
