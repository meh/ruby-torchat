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

# The groupchat extension is made to support, you can guess it, groupchats.
#
# The following text describes the lifecycle of a group chat.
#
# The person that starts the groupchat starts it by inviting the first person
# to it, the invite packet has a cookie inside that will also be the id of the
# groupchat throughout all its lifecycle.
#
# After the invite packet a participants packet is sent to the invited person,
# this packet has inside the list of ids of the current groupchat.
#
# After receiving the participants packet the invited starts connections to all the
# participants and sends them a packet asking them if they're really participating
# in the groupchat. The contacts that aren't in his buddy list are added as temporary
# buddies. If any of the participants are in his blocked list, a leave packet will be
# sent, refusing to join the groupchat, otherwise a join packet will be sent.
#
# After the participants packet an invited packet is sent to the already present participants,
# in this way they'll know who invited that person and that that person is going to join the
# groupchat.
#
# The messaging in the groupchat is simply sent to every other participant from the sender
# of the message.
#
# To exit the groupchat a leave packet is sent to every participant present in the groupchat.
#
# On disconnection of any of the participants it will obviously mean leaving the groupchat.
define_extension :groupchat do
	# This packet is sent to the person you want to invite to the groupchat,
	# the packet only contains the id of the groupchat.
	define_packet :invite do
		define_unpacker_for 1

		def initialize (id = nil)
			@internal = id || Torchat.new_cookie
		end

		def id
			@internal
		end
	end

	# This packet is used to tell the invited who are the participants.
	define_packet :participants do
		define_unpacker_for 1 .. -1

		attr_accessor :id

		def initialize (id, *participants)
			@id = id

			@internal = participants.flatten.uniq
		end

		def method_missing (id, *args, &block)
			return @internal.__send__ id, *args, &block if @internal.respond_to? id

			super
		end

		def pack
			super("#{id} #{join ' '}")
		end
	end

	# This packet is used to ask if the person is really participating in the groupchat
	define_packet :participating? do
		define_unpacker_for 1

		def id
			@internal
		end
	end

	# This packet is sent to accept the invitation to the groupchat
	define_packet :join do
		define_unpacker_for 1

		def id
			@internal
		end
	end

	# This packet is sent to every participant in a groupchat to tell them you're leaving
	define_packet :leave do
		define_unpacker_for 1 .. 2

		attr_accessor :id, :reason

		def initialize (id, reason = nil)
			@id = id

			@reason = reason
		end
	end

	# This packet is used to tell the already present participants about who you invited.
	define_packet :invited do
		define_unpacker_for 2

		attr_accessor :id

		def initialize (id, buddy)
			@id = id

			@internal = buddy.is_a?(Buddy) ? buddy.id : buddy
		end

		def pack
			super("#{id} #{to_s}")
		end

		def to_s
			@internal
		end

		alias to_str to_s
	end

	# This packet is sent to all participants and is just a message.
	define_packet :message do
		define_unpacker_for 2

		attr_accessor :id

		def initialize (id, message)
			@id = id

			@internal = message
		end

		def pack
			super("#{id} #{message}")
		end

		def to_s
			@internal
		end

		alias to_str to_s
	end
end

end; end
