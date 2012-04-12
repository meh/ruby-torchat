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

require 'torchat/session/buddy'

class Torchat; class Session

class Buddies < Hash
	attr_reader :session

	def initialize (session)
		@session = session
	end

	def has_key? (name)
		name = name.id if name.is_a? Buddy

		!!self[name]
	end

	def delete (name)
		super(self[name].id) rescue nil
	end

	def [] (name)
		name = name.id if name.is_a? Buddy

		super(name) || super(name[/^(.*?)(\.onion)?$/, 1]) || find { |a, b| name === b.name }
	end

	def []= (name, buddy)
		name = name.id if name.is_a? Buddy

		unless Tor.valid_address?(name) || Tor.valid_id?(name)
			name = find { |a, b| name === b.name }.id
		end

		name = name[/^(.*?)(\.onion)?$/, 1]

		super(name, buddy)
	end

	def << (buddy)
		self[buddy.id] = buddy
	end

	def add (id, ali = nil)
		if buddy = self[id]
			buddy.permanent!

			return buddy
		end

		buddy = if id.is_a? Buddy
			id
		else
			Buddy.new(session, id)
		end

		raise ArgumentError, 'you cannot add yourself' if session.id == buddy.id

		buddy.permanent!
		buddy.alias = ali
		
		self << buddy and fire :added, buddy

		buddy.connect if online?

		buddy
	end

	def add_temporary (id, ali = nil)
		if buddy = self[id]
			return buddy
		end

		buddy = if id.is_a? Buddy
			id
		else
			Buddy.new(session, id)
		end

		raise ArgumentError, 'you cannot add yourself' if session.id == buddy.id

		buddy.temporary!
		buddy.alias = ali

		self << buddy and fire :added, buddy

		buddy.connect if online?

		buddy
	end

	def remove (id)
		return unless has_key? id

		buddy = if id.is_a? Buddy
			delete(key(id))
		else
			delete(id)
		end

		buddy.remove!

		session.fire :removal, buddy

		if buddy.permanent?
			buddy.send_packet :remove_me

			session.set_timeout 5 do
				buddy.disconnect
			end
		else
			buddy.disconnect
		end

		buddy
	end
end

end; end
