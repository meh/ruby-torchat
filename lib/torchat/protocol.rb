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

@packets    = Hash.new { |h, k| h[k] = {} }
@extensions = []

def self.[] (extension = nil, name)
	extension = extension.to_sym.downcase if extension
	name      = name.to_sym.downcase

	@packets[extension][name]
end

def self.[]= (extension = nil, name, value)
	extension = extension.to_sym.downcase if extension
	name      = name.to_sym.downcase

	if value.nil?
		@packets[extension].delete(name)
	else
		@packets[extension][name] = value
	end
end

def self.has_packet? (extension = nil, name)
	extension = extension.to_sym.downcase if extension
	name      = name.to_sym.downcase

	@packets[extension].has_key?(name)
end

def self.packets
	@packets.map { |extension, packets|
		packets.map { |name, packet|
			packet
		}
	}.flatten
end

def self.extensions
	@extensions.map {|name|
		Struct.new(:name, :packets).new(name, packets(name))
	}
end

def self.define_packet (name, &block)
	raise ArgumentError, "#{name} already exists" if has_packet?(@extension, name)

	self[@extension, name] = Packet.define(name, @extension, &block)
end

def self.define_packet! (name, &block)
	self[@extension, name] = nil

	define_packet(name, &block)
end

def self.define_extension (name)
	@extensions.push(name).uniq!

	tmp, @extension = @extension, name
	result = yield
	@extension = tmp

	result
end

def self.packet (*args)
	if args.first.is_a? Packet
		args.first
	else
		unless packet = self[*args.shift]
			raise ArgumentError, "#{name} packet unknown"
		end

		packet.new(*args)
	end
end

def self.unpack (data, from = nil)
	name, data = data.chomp.split(' ', 2)

	unless packet = self[name] || self[*name.split('_', 2)]
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
