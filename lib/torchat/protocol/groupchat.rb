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
	define_packet :invite do
		define_unpacker_for 1

		def initialize (id = nil)
			@internal = id || Torchat.new_cookie
		end

		def id
			@internal
		end

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id})>"
		end
	end

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

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id}): #{@internal.join ', '}>"
		end
	end

	define_packet :participating? do
		define_unpacker_for 1

		def id
			@internal
		end

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id})>"
		end
	end

	define_packet :participating! do
		define_unpacker_for 1

		def id
			@internal
		end

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id})>"
		end
	end

	define_packet :join do
		define_unpacker_for 1

		def id
			@internal
		end

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id})>"
		end
	end

	define_packet :leave do
		define_unpacker_for 1 .. 2

		attr_accessor :id, :reason

		def initialize (id, reason = nil)
			@id = id

			@reason = reason
		end

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id})#{": #{reason.inspect}" if reason}>"
		end
	end

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

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id}): #{to_s.inspect}>"
		end
	end

	define_packet :message do
		define_unpacker_for 2

		attr_accessor :id

		def initialize (id, message)
			@id = id

			@internal = message
		end

		def pack
			super("#{id} #{to_s}")
		end

		def to_s
			@internal
		end

		alias to_str to_s

		def inspect
			"#<Torchat::Packet[#{type}#{", #{extension}" if extension}](#{id}): #{to_s.inspect}>"
		end
	end
end

end; end
