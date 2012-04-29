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

require 'delegate'

require 'torchat/session/group_chat'

class Torchat; class Session; class Buddy

class JoinedGroupChat < DelegateClass(GroupChat)
	def initialize (group_chat, buddy)
		super(group_chat)

		@buddy = buddy
	end

	def leave (reason = nil)
		group_chat.delete(@buddy)

		group_chat.session.fire :group_chat_leave, group_chat: group_chat, buddy: @buddy, reason: reason
	end

	alias ~ __getobj__
end

end; end; end
