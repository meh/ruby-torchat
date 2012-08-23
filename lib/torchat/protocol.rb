#--
# Copyleft meh. [http://meh.schizofreni.co | meh@schizofreni.co]
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

def self.packets (extension = nil)
	if extension
		@packets[extension].values
	else
		@packets.map { |extension, packets|
			packets.map { |name, packet|
				packet
			}
		}.flatten
	end
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
		unless packet = self[*args.first]
			raise ArgumentError, "#{args.first.inspect} packet unknown"
		end

		args.shift

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

class Packet
	def self.define (name, extension = nil, &block)
		Class.new(self, &block).tap {|c|
			c.instance_eval {
				define_singleton_method :type do name end
				define_method :type do name end

				define_singleton_method :extension do extension end
				define_method :extension do extension end

				define_singleton_method :inspect do
					"#<Torchat::Packet: #{"#{extension}_" if extension}#{type}>"
				end
			}
		}
	end

	def self.define_unpacker (&block)
		define_singleton_method :unpack do |data|
			new(*block.call(data))
		end
	end

	def self.define_unpacker_for (range, &block)
		unless range.is_a? Range
			range = range .. range
		end

		if block
			define_unpacker &block
		else
			define_unpacker do |data|
				if data.nil? || data.empty?
					if range.begin == 0 || range.end == 0
						next
					else
						raise ArgumentError, "wrong number of arguments (0 for #{range.begin})"
					end
				end

				args  = range.end == -1 ? data.split(' ') : data.split(' ', range.end)
				arity = range.end == -1 ? range.begin .. args.length : range

				if args.last && args.last.empty?
					args[-1] = nil
				end

				unless arity === args.length
					raise ArgumentError, "wrong number of arguments (#{args.length} for #{args.length < range.begin ? range.begin : range.end})"
				end

				args
			end
		end

		if range == (0 .. 0)
			define_method :pack do
				super('')
			end

			define_method :inspect do
				"#<Torchat::Packet[#{"#{extension}_" if extension}#{type}]>"
			end
		elsif range.end == 1
			if range.begin == 0
				define_method :initialize do |value = nil|
					@internal = value
				end
			else
				define_method :initialize do |value|
					@internal = value
				end
			end

			define_method :pack do
				super(@internal.to_s)
			end

			define_method :nil? do
				@internal.nil?
			end

			define_method :inspect do
				"#<Torchat::Packet[#{"#{extension}_" if extension}#{type}]#{": #{@internal.inspect}" if @internal}>"
			end
		else
			define_method :initialize do |*args|
				@internal = args
			end

			define_method :inspect do
				"#<Torchat::Packet[#{"#{extension}_" if extension}#{type}]: #{@internal.map(&:inspect).join(', ')}>"
			end
		end
	end

	def self.new (*args, &block)
		super(*args, &block).tap {|packet|
			packet.at = Time.new
		}
	end

	attr_accessor :from, :at

	def pack (data)
		"#{"#{extension}_" if extension}#{type}#{" #{Protocol.encode(data)}" if data}\n"
	end
end

require 'torchat/protocol/standard'
require 'torchat/protocol/groupchat'
require 'torchat/protocol/typing'
require 'torchat/protocol/broadcast'
require 'torchat/protocol/latency'

end; end
