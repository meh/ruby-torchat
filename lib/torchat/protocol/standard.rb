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

define_packet :not_implemented do
	define_unpacker_for 0 .. 1

	def command
		@internal
	end
end

define_packet :ping do
	define_unpacker_for 2

	attr_reader   :id, :address
	attr_accessor :cookie

	def initialize (address, cookie = nil)
		super()

		self.address = address
		self.cookie  = cookie || Torchat.new_cookie
	end

	def id= (value)
		@id      = value[/^(.*?)(\.onion)?$/, 1]
		@address = "#{@id}.onion"
	end

	alias address= id=

	def valid?
		Tor.valid_id? @id
	end

	def pack
		super("#{id} #{cookie}")
	end

	def inspect
		"#<Torchat::Packet[#{type}]#{"(#{from.inspect})" if from}: #{id} #{cookie}>"
	end
end

define_packet :pong do
	define_unpacker_for 1

	def cookie
		@internal
	end
end

define_packet :client do
	define_unpacker_for 1

	def name
		@internal
	end

	alias to_s   name
	alias to_str name
end

define_packet :version do
	define_unpacker_for 1

	def to_s
		@internal
	end

	alias to_str to_s
end

define_packet :supports do
	define_unpacker_for 0 .. -1

	def initialize (*supports)
		super()

		@internal = supports.flatten.compact.map(&:downcase).map(&:to_sym).uniq
	end

	def method_missing (id, *args, &block)
		return @internal.__send__ id, *args, &block if @internal.respond_to? id

		super
	end

	def pack
		super(join ' ')
	end
end

define_packet :status do
	def self.valid? (name)
		%w(available away xa).include?(name.to_s.downcase)
	end

	define_unpacker_for 1

	def initialize (name)
		unless Protocol[:status].valid?(name)
			raise ArgumentError, "#{name} is not a valid status"
		end

		super()

		@internal = name.to_sym.downcase
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
		to_sym.to_s
	end
end

define_packet :profile_name do
	define_unpacker_for 0 .. 1 do |data|
		data.force_encoding('UTF-8') if data
	end

	def pack
		super(@internal ? @internal.encode('UTF-8') : nil)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

define_packet :profile_text do
	define_unpacker_for 0 .. 1 do |data|
		data.force_encoding('UTF-8') if data
	end

	def pack
		super(@internal ? @internal.encode('UTF-8') : nil)
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

define_packet :profile_avatar_alpha do
	define_unpacker_for 0 .. 1 do |data|
		data if data && (data.empty? || data.bytesize != 4096)
	end

	def data
		@internal
	end

	def inspect
		"#<Torchat::Packet[#{type}]>"
	end
end

define_packet :profile_avatar do
	define_unpacker_for 0 .. 1 do |data|
		data if data && (data.empty? || data.bytesize == 12288)
	end

	def data
		@internal
	end

	def inspect
		"#<Torchat::Packet[#{type}]>"
	end
end

define_packet :add_me do
	define_unpacker_for 0
end

define_packet :remove_me do
	define_unpacker_for 0
end

define_packet :message do
	define_unpacker_for 1 do |data|
		data.force_encoding('UTF-8')
	end

	def pack
		super(@internal.encode('UTF-8'))
	end

	def to_s
		@internal
	end

	alias to_str to_s
end

define_packet :filename do
	define_unpacker do |data|
		id, size, block_size, name = data.split ' ', 4

		[name, size, block_size, id]
	end

	attr_accessor :id, :name, :size, :block_size

	def initialize (name, size, block_size = 4096, id = nil)
		super()

		@name       = name
		@size       = size.to_i
		@block_size = block_size.to_i
		@id         = id || Torchat.new_cookie
	end

	alias length   size
	alias bytesize size

	def pack
		super("#{id} #{size} #{block_size} #{name}")
	end

	def inspect
		"#<Torchat::Packet[#{type}](#{id}): #{name} #{size} #{block_size}>"
	end
end

define_packet :filedata do
	define_unpacker do |data|
		id, offset, md5, data = data.split ' ', 4

		[id, offset, data, md5]
	end

	attr_reader   :data, :md5
	attr_accessor :id, :offset

	def initialize (id, offset, data, md5 = nil)
		super()

		@id     = id
		@offset = offset.to_i
		@data   = data.force_encoding('BINARY')
		@md5    = md5 || Digest::MD5.hexdigest(@data)
	end

	def data= (value)
		@data = value.to_s.force_encoding('BINARY')
		@md5  = Digest::MD5.hexdigest(@data)
	end

	def valid?
		Digest::MD5.hexdigest(data) == md5
	end

	def pack
		super("#{id} #{offset} #{md5} #{data}")
	end

	def inspect
		"#<Torchat::Packet[#{type}](#{id}): #{offset} #{data.size}>"
	end
end

define_packet :filedata_ok do
	define_unpacker do |data|
		data.split ' '
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

	def inspect
		"#<Torchat::Packet[#{type}](#{id}): #{offset}>"
	end
end

define_packet :filedata_error do
	define_unpacker do |data|
		data.split ' '
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

	def inspect
		"#<Torchat::Packet[#{type}](#{id}): #{offset}>"
	end
end

define_packet :file_stop_sending do
	define_unpacker_for 1

	def id
		@internal
	end

	def inspect
		"#<Torchat::Packet[#{type}](#{id})>"
	end
end

define_packet :file_stop_receiving do
	define_unpacker_for 1

	def id
		@internal
	end

	def inspect
		"#<Torchat::Packet[#{type}](#{id})>"
	end
end

end; end
