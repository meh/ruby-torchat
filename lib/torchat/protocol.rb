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

def self.valid_address? (address)
	!!address.match(/^[234567abcdefghijklmnopqrstuvwxyz]{16}(\.onion)?$/)
end

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

class Packet
	def self.type
		name[/(::)?([^:]+)$/, 2].gsub(/([A-Z])/) { '_' + $1.downcase }[1 .. -1].to_sym
	end

	def self.[] (name)
		Protocol.const_get(name.to_s.gsub(/(\A|_)(\w)/) { $2.upcase })
	end

	def self.unpack (data)
		name, data = data.split(' ', 2)

		self[name].unpack(data ? Protocol.decode(data) : nil)
	end

	def self.from (from, data)
		unpack(data).tap { |p| p.from = from }
	end

	attr_accessor :from

	def type
		self.class.type
	end

	def pack (data)
		"#{type}#{" #{Protocol.encode(data)}" if data && !data.empty?}\n"
	end

	class NoValue < Packet
		def self.unpack (data)
			new
		end

		def pack
			super('')
		end

		def inspect
			"#<#{self.class.name}#{"(#{from.inspect})" if from}>"
		end
	end

	class SingleValue < Packet
		def self.unpack (data)
			if data.nil? || data.empty?
				raise ArgumentError, 'missing value for packet'
			end

			new(data)
		end

		def initialize (value)
			@internal = value
		end

		def pack
			super(@internal)
		end

		def inspect
			"#<#{self.class.name}#{"(#{from.inspect})" if from}: #{@internal.inspect}>"
		end
	end
end

class NotImplemented < Packet::SingleValue
	def command
		@internal
	end
end

class Ping < Packet
	def self.unpack (data)
		if data.nil? || (tmp = data.split(' ')).length != 2
			raise ArgumentError, 'not enough values in the packet'
		end

		new(*tmp)
	end

	attr_reader   :id, :address
	attr_accessor :cookie

	def initialize (address, cookie = nil)
		@cookie  = cookie || rand.to_s

		self.address = address
	end

	def id= (value)
		@id      = value[/^(.*?)(\.onion)?$/, 1]
		@address = "#{@id}.onion"
	end

	alias address= id=

	def valid?
		Protocol.valid_address?(@address)
	end

	def pack
		super("#{id} #{cookie}")
	end

	def inspect
		"#<#{self.class.name}#{"(#{from.inspect})" if from}: #{id} #{cookie}>"
	end
end

class Pong < Packet::SingleValue
	def cookie
		@internal
	end
end

class Client < Packet::SingleValue
	def name
		@internal
	end

	alias to_s   name
	alias to_str name
end

class Version < Packet::SingleValue
	def to_s
		@internal
	end

	alias to_str to_s
end

class Status < Packet::SingleValue
	def initialize (name)
		@internal = name.to_s.downcase
	end

	def available?
		@internal == 'available'
	end

	def away?
		@internal == 'away'
	end

	def extended_away?
		@internal == 'xa'
	end
end

class ProfileName < Packet::SingleValue
	def initialize (name)
		@internal = name.encode('UTF-8')
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileText < Packet::SingleValue
	def initialize (text)
		@internal = text.encode('UTF-8')
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileAvatarAlpha < Packet::SingleValue
	def self.unpack (data)
		new(data && data.empty? ? nil : data)
	end

	def nil?
		@internal.nil?
	end

	def data
		@internal
	end

	def inspect
		"#<#{self.class.name}>"
	end
end

class ProfileAvatar < Packet::SingleValue
	def self.unpack (data)
		new(data && data.empty? ? nil : data)
	end

	def nil?
		@internal.nil?
	end

	def data
		@internal
	end

	def inspect
		"#<#{self.class.name}>"
	end
end

class AddMe < Packet::NoValue
end

class RemoveMe < Packet::NoValue
end

class Message < Packet::SingleValue
	def initialize (data)
		@internal = data.encode('UTF-8')
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

class FileStopSending < Packet::SingleValue
	def initialize (id)
		@internal = id || rand.to_s
	end

	def id
		@internal
	end
end

class FileStopReceiving < Packet::SingleValue
	def initialize (id)
		@internal = id || rand.to_s
	end

	def id
		@internal
	end
end

end; end
