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

require 'torchat/session/buddy/joined_group_chat'

class Torchat; class Session; class Buddy

class JoinedGroupChats < Hash
	attr_reader :buddy

	def initialize (buddy)
		@buddy = buddy
	end

	def add (id)
		group_chat = id.is_a?(GroupChat) ? id : buddy.session.group_chats[id]

		if group_chat
			self[group_chat.id] = JoinedGroupChat.new(group_chat, buddy)
		end
	end

	def delete (id)
		super(id.respond_to?(:id) ? id.id : id)
	end

	private :[]=
end

end; end; end
