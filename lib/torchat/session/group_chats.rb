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

require 'torchat/session/group_chat'

class Torchat; class Session

class GroupChats < Hash
	attr_reader :session

	def initialize (session)
		@session = session
	end

	def has_key? (name)
		name = name.id if name.is_a? GroupChat

		!!self[name]
	end

	def [] (name)
		name = name.id if name.is_a? GroupChat

		super(name)
	end

	private :[]=

	def create (id = Torchat.new_cookie, joined = true)
		if has_key? id
			raise ArgumentError, "a groupchat named #{id} already exists"
		end

		GroupChat.new(session, id).tap {|group_chat|
			group_chat.joined! if joined

			self[id] = group_chat

			session.fire :group_chat_create, group_chat: group_chat
		}
	end

	def destroy (id)
		unless has_key? id
			raise ArgumentError, "a groupchat named #{id} doesn't exists"
		end

		self[id].tap {|group_chat|
			delete group_chat.id

			session.fire :group_chat_destroy, group_chat: group_chat
		}
	end

	private :delete
end

end; end
