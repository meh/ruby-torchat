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

class Torchat; module Protocol

define_extension :groupchat do
	# this packet is sent to the person you want to invite to the groupchat
	# the packet only contains the id of the groupchat
	define_packet :groupchat_invite do
		define_unpacker_for 1

		def initialize (id = nil)
			@internal = id || rand.to_s
		end

		def id
			@internal
		end
	end

	define_packet :groupchat_invited do

	end

	define_packet :groupchat_participants do

	end

	define_packet :groupchat_message do
		define_unpacker_for 2

		attr_accessor :id, :message

		def initialize (id, message)
			@id      = id
			@message = message
		end
	end
end

end; end
