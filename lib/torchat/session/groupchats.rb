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

require 'torchat/session/groupchat'

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

	def create (id = Torchat.new_cookie)
		self[id] = GroupChat.new(session, id)
	end
end

end; end
