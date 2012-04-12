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

@packets    = {}
@extensions = []

def self.[] (name)
	@packets[name.to_sym.downcase]
end

def self.[]= (name, value)
	if value.nil?
		@packets.delete(name.to_sym.downcase)
	else
		@packets[name.to_sym.downcase] = value
	end
end

def self.has_packet? (name)
	@packets.has_key?(name.to_sym.downcase)
end

def self.packets
	@packets.values
end

def self.extensions
	@extensions.map {|name|
		Struct.new(:name, :packets).new(name, packets.select { |p| p.extension == name })
	}
end

def self.define_packet (name, &block)
	raise ArgumentError, "#{name} already exists" if has_packet?(name)

	self[name] = Packet.define(name, @extension, &block)
end

def self.define_packet! (name, &block)
	self[name] = nil

	define_packet(name, &block)
end

def self.define_extension (name)
	@extensions.push(name).uniq!

	@extension = name
	result = yield
	@extension = nil

	result
end

def self.packet (*args)
	if args.first.is_a? Packet
		args.first
	else
		unless packet = self[args.shift]
			raise ArgumentError, "#{name} packet unknown"
		end

		packet.new(*args)
	end
end

def self.unpack (data, from = nil)
	name, data = data.chomp.split(' ', 2)

	unless packet = self[name]
		raise ArgumentError, "#{name} packet unknown"
	end

	unless packet.respond_to? :unpack
		raise ArgumentError, "#{name} packet has no unpacker"
	end

	packet      = packet.unpack(data ? decode(data) : nil)
	packet.from = from

	packet
end

require 'torchat/protocol/standard'
require 'torchat/protocol/groupchat'

end; end
