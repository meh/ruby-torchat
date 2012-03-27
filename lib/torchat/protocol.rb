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

class Packet
	def self.encode (data)
		data = data.dup

		data.force_encoding 'BINARY'
		data.gsub!("\\", "\\/")
		data.gsub!("\n", "\\n")

		data
	end

	def self.decode (data)
		data = data.dup

		data.force_encoding 'BINARY'
		data.gsub!("\\n", "\n")
		data.gsub!("\\/", "\\")

		data
	end

	def self.unpack (data)
		name, data = data.split(' ', 2)

		Protocol.const_get(name.gsub(/(\A|_)(\w)/) { $2.upcase }).unpack(data ? decode(data) : nil)
	end

	def self.from (from, data)
		unpack(data).tap { |p| p.from = from }
	end

	attr_accessor :from

	def pack (data)
		self.class.name[/(::)?([^:]+)$/, 2].gsub(/([A-Z])/) { '_' + $1.downcase }[1 .. -1] + Packet.encode(data)
	end
end

class NotImplemented < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :command

	def initialize (command)
		@command = command
	end

	def pack
		super(command)
	end
end

class Ping < Packet
	def self.unpack (data)
		new(*data.split(' '))
	end

	attr_accessor :address, :cookie

	def initialize (address, cookie = nil)
		@address = address
		@cookie  = cookie || rand.to_s
	end

	def valid?
		!!@address.match(/^[234567abcdefghijklmnopqrstuvwxyz]{16}$/)
	end

	def pack
		super("#{address} #{cookie}")
	end
end

class Pong < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :cookie

	def initialize (cookie)
		@cookie = cookie
	end

	def pack
		super(cookie)
	end
end

class Client < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :name

	def initialize (name)
		@name = name
	end

	def pack
		super(name)
	end

	def to_s
		name
	end

	alias to_str to_s
end

class Version < Packet
	def self.unpack (data)
		new(data)
	end

	def initialize (value)
		@internal = value
	end

	def pack
		super(@internal)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class Status < Packet
	def self.unpack (data)
		new(data)
	end

	attr_reader :name

	def initialize (name)
		@name = name.to_s.downcase
	end

	def available?
		@name == 'available'
	end

	def away?
		@name == 'away'
	end

	def extended_away?
		@name == 'xa'
	end

	def pack
		super(name)
	end
end

class ProfileName < Packet
	def self.unpack (data)
		new(data)
	end

	def initialize (name)
		@internal = name.encode('UTF-8')
	end

	def pack
		super(@internal)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileText < Packet
	def self.unpack (data)
		new(data)
	end

	def initialize (text)
		@internal = text.encode('UTF-8')
	end

	def pack
		super(@internal)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileAvatarAlpha < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :data

	def initialize (data)
		@data = data
	end
end

class ProfileAvatar < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :data

	def initialize (data)
		@data = data
	end
end

class AddMe < Packet
	def self.unpack (data)
		new
	end

	def pack
		super('')
	end
end

class RemoveMe < Packet
	def self.unpack (data)
		new
	end

	def pack
		super('')
	end
end

class Message < Packet
	def self.unpack (data)
		new(data)
	end

	def initialize (data)
		@internal = data.encode('UTF-8')
	end

	def pack
		super(@internal)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class Filename < Packet
	def self.unpack (data)
		id, file_size, bock_size, file_name = data.split ' '

		new(file_name, file_size, block_size, id)
	end

	attr_accessor :id, :name, :file_size, :block_size

	def initialize (name, file_size, block_size, id = nil)
		@id = id || rand.to_s

		@name       = name
		@file_size  = file_size.to_i
		@block_size = block_size.to_i
	end

	def bytesize
		@file_size * @block_size
	end

	def pack
		super("#{id} #{file_size} #{block_size}")
	end
end

class Filedata < Packet
	def self.unpack (data)
		id, start, md5, data = data.split ' '

		new(start, hash, data, id)
	end

	attr_accessor :id, :start_at, :data

	def initialize (start, md5, data, id = nil)
		@id = id || rand.to_s

		@start_at = start.to_i
		@md5      = md5
		@data     = data
	end

	def valid?
		Digest::MD5.hexdigest(data) == @md5
	end

	def pack
		super("#{id} #{start} #{hash} #{data}")
	end
end

class FiledataOk < Packet
	def self.unpack (data)
		id, start = data.split ' '

		new(start, id)
	end

	attr_accessor :id, :start_at

	def initialize (start, id = nil)
		@id = id

		@start_at = start.to_i
	end

	def pack
		super("#{id} #{start_at}")
	end
end

class FiledataError < Packet
	def self.unpack (data)
		id, start = data.split ' '

		new(start, id)
	end

	attr_accessor :id, :start_at

	def initialize (start, id = nil)
		@id = id

		@start_at = start.to_i
	end

	def pack
		super("#{id} #{start_at}")
	end
end

class FileStopSending < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :id

	def initialize (id)
		@id = id || rand.to_s
	end

	def pack
		super('')
	end
end

class FileStopReceiving < Packet
	def self.unpack (data)
		new(data)
	end

	attr_accessor :id

	def initialize (id)
		@id = id || rand.to_s
	end

	def pack
		super('')
	end
end

end; end
