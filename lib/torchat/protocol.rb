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

require 'digest/md5'

class Torchat; module Protocol

def self.valid_address? (address)
	!!address.match(/^[234567abcdefghijklmnopqrstuvwxyz]{16}(\.onion)?$/i)
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

	def self.create (*args)
		if args.first.is_a? Symbol
			Protocol::Packet[args.shift].new(*args)
		else
			args.first
		end
	end

	attr_accessor :from, :at

	def initialize
		@at = Time.new
	end

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
		def self.can_be_nil!
			@can_be_nil = true
		end

		def self.can_be_nil?
			@can_be_nil
		end

		def self.unpack (data)
			if data.nil? || data.empty?
				if can_be_nil?
					data = nil
				else
					raise ArgumentError, 'missing value for packet'
				end
			end

			new(data)
		end

		def initialize (value)
			super()

			@internal = value
		end

		def nil?
			@internal.nil?
		end

		def pack
			super(@internal.to_s)
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
		super()

		@cookie = cookie || rand.to_s

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
	def self.valid? (name)
		%w(available away xa).include?(name.to_s.downcase)
	end

	def initialize (name)
		unless Status.valid?(name)
			raise ArgumentError, "#{name} is not a valid status"
		end

		super(name.to_sym.downcase)
	end

	def available?
		@internal == :available
	end

	def away?
		@internal == :away
	end

	def extended_away?
		@internal == :xa
	end

	def to_sym
		@internal
	end

	def to_s
		@internal.to_s
	end
end

class ProfileName < Packet::SingleValue
	can_be_nil!

	def initialize (name)
		super(name.force_encoding('UTF-8')) if name
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileText < Packet::SingleValue
	can_be_nil!

	def initialize (text)
		super(text.force_encoding('UTF-8')) if text
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class ProfileAvatarAlpha < Packet::SingleValue
	def self.unpack (data)
		new(data && data.empty? || data.bytesize != 4096 ? nil : data)
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
		new(data && data.empty? || data.bytesize != 12288 ? nil : data)
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
		super(data.force_encoding('UTF-8'))
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

class Filename < Packet
	def self.unpack (data)
		id, file_size, bock_size, file_name = data.split ' '

		new(id, file_name, file_size, block_size)
	end

	attr_accessor :id, :name, :size, :block_size

	def initialize (id, name, size, block_size)
		super()

		@id         = id
		@name       = name
		@size       = size.to_i
		@block_size = block_size.to_i
	end

	alias length size

	alias bytesize size

	def pack
		super("#{id} #{file_size} #{block_size}")
	end
end

class Filedata < Packet
	def self.unpack (data)
		id, offset, md5, data = data.split ' '

		new(id, offset, data, md5)
	end

	attr_accessor :id, :offset, :data

	def initialize (id, offset, data, md5 = nil)
		super()

		@id     = id
		@offset = offset.to_i
		@data   = data.force_encoding('BINARY')
		@md5    = md5 || Digest::MD5.hexdigest(data)
	end

	def valid?
		Digest::MD5.hexdigest(data) == @md5
	end

	def pack
		super("#{id} #{offset} #{hash} #{data}")
	end
end

class FiledataOk < Packet
	def self.unpack (data)
		id, offset = data.split ' '

		new(id, offset)
	end

	attr_accessor :id, :offset

	def initialize (id, offset)
		super()

		@id     = id
		@offset = offset.to_i
	end

	def pack
		super("#{id} #{offset}")
	end
end

class FiledataError < Packet
	def self.unpack (data)
		id, offset = data.split ' '

		new(offset, id)
	end

	attr_accessor :id, :offset

	def initialize (id, offset)
		super()

		@offset = offset.to_i
		@id     = id || rand.to_s
	end

	def pack
		super("#{id} #{offset}")
	end
end

class FileStopSending < Packet::SingleValue
	def initialize (id)
		super(id)
	end

	def id
		@internal
	end
end

class FileStopReceiving < Packet::SingleValue
	def initialize (id)
		super(id)
	end

	def id
		@internal
	end
end

end; end
