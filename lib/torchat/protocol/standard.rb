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

# The following text describes the lifecycle of a standard torchat session.
#
# The connection to a buddy can be initiated from the buddy or from yourself,
# to establish a connection succesfully both ends must be connected to eachother
# with two different sockets. This is needed to ensure that we're talking with
# the real owner of the id. The id is nothing more than an onion id for a Tor
# hidden service. The protocol requires in fact that a Tor session is running
# with a hidden service configured to receive connections on the 11109 port.
#
# When we receive an incoming connection from a buddy he has to send a ping packet,
# this packet contains the address of the presumed connected buddy and a cookie.
# Once we receive this ping packet we try connecting on the address contained in the ping.
# Once the connection is successful we send a ping packet with our address and a new cookie,
# and a pong packet with the received cookie. After this the other end is supposed to send
# us a pong packet with our cookie. If everything went right and all cookies were right
# the connection has been verified correctly. It obviously can go the other way around.
#
# Once the connection has been verified, both ends send a certain number of packets.
# All these packets are:
#   - the client packet, that tells what client we are using
#   - the version packet, that tells the version of the client
#   - the supports packet with the supported extensions (this is an extension itself)
#   - the profile name packet, that tells our name (optional)
#   - the profile text, that tells our description (optional)
#   - if this is a permanent buddy, an add me packet
#   - a status packet telling what's our status
#
# After this, the status packet is used as a keep alive and must be sent every 120 seconds.
#
# A remove me packet can be sent to make the other end remove us from their contact list.
#
# Messages are simply sent to the buddy.

# This packet is sent when we receive a packet we don't know about.
#
# It can contain the name of the packet or just nothing.
define_packet :not_implemented do
	define_unpacker_for 0 .. 1

	def command
		@internal
	end
end

# This packet is used as the entry point for authentication,
# it contains the address of the sender and cookie.
#
# Once received the receiver has to send back a pong packet with the cookie.
#
# Despite the name it's not actually used as keep alive packet.
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

# This packet is the endpoint of the authentication, it contains the cookie
# received in the ping packet.
#
# Despite the name it's not actually used as keep alive packet.
define_packet :pong do
	define_unpacker_for 1

	def cookie
		@internal
	end
end

# This packet tells the other end what client we are using.
define_packet :client do
	define_unpacker_for 1

	def name
		@internal
	end

	alias to_s   name
	alias to_str name
end

# This packet tells the other end the version of the client we are using.
define_packet :version do
	define_unpacker_for 1

	def to_s
		@internal
	end

	alias to_str to_s
end

# This packet is an embedded extension of the standard protocol, it's used
# to tell the other end what protocol extensions we support.
define_packet :supports do
	define_unpacker_for 0 .. -1

	def initialize (*supports)
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

# This packet tells the other end our status, it's also used as keep alive packet.
#
# The current supported status names are: available, away and xa.
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

# This packet tells the other end our name, it can be empty.
#
# The name has to be encoded in UTF-8.
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

# This packet tells the other end our description, it can be empty.
#
# The description has to be encoded in UTF-8.
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

# This packet sends the other end the alpha channel of our avatar.
#
# If the image has no alpha channel its content is empty, it MUST be
# sent before the profile_avatar packet.
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

# This packet sends the other end the rgb channels of our avatar.
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

# This packet is sent to make the other end add yourself to the permanent contacts.
#
# In the standard protocol, this is useless, I support the temporary contacts because
# it is useful in the case of groupchats.
define_packet :add_me do
	define_unpacker_for 0
end

# This packet is sent to make the other end delete us.
#
# The other end has to disconnect, not us.
define_packet :remove_me do
	define_unpacker_for 0
end

# This packet is sent to send a message.
#
# The message has to be encoded in UTF-8.
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

# This packet is sent to start a file transfer.
#
# It contains the id, the file name, the size and the block size.
define_packet :filename do
	define_unpacker do |data|
		id, size, bock_size, name = data.split ' ', 4

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
end

# This packet sends a block of the file to transfer.
#
# It contains the id, the offset, the content and an useless md5.
#
# Every filedata packet has to be answered with a filedata_ok or a filedata_error.
define_packet :filedata do
	define_unpacker do |data|
		id, offset, md5, data = data.split ' ', 4

		[id, offset, data, md5]
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

# This packet tells the other end that a block of the file has been passed successfully.
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
end

# This packet tells the other end that there's been an error in receiving a block.
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
end

# This packet tells the other end to stop sending the file.
define_packet :file_stop_sending do
	define_unpacker_for 1

	def id
		@internal
	end
end

# This packet tells the other end to stop receiving the file.
define_packet :file_stop_receiving do
	define_unpacker_for 1

	def id
		@internal
	end
end

end; end
