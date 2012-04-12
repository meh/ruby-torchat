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

class Packet
	def self.define (name, extension = nil, &block)
		Class.new(self, &block).tap {|c|
			c.instance_eval {
				define_singleton_method :type do name end
				define_method :type do name end

				define_singleton_method :extension do extension end
				define_method :extension do extension end

				define_singleton_method :inspect do
					"#<Torchat::Packet: #{type}#{", #{extension}" if extension}>"
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

				args = data.split ' ', range.end

				if range.end == -1
					range = range.begin .. args.length
				end

				unless range === args.length
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
				"#<Torchat::Packet[#{type}]#{"(#{from.inspect})" if from}>"
			end
		elsif range.end == 1
			if range.begin == 0
				define_method :initialize do |value = nil|
					super()

					@internal = value
				end
			else
				define_method :initialize do |value|
					super()

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
				"#<Torchat::Packet[#{type}]#{"(#{from.inspect})" if from}#{": #{@internal.inspect}" if @internal}>"
			end
		else
			define_method :initialize do |*args|
				super()

				@internal = args
			end

			define_method :inspect do
				"#<Torchat::Packet[#{type}]#{"(#{from.inspect})" if from}: #{@internal.map(&:inspect).join(', ')}>"
			end
		end
	end

	attr_accessor :from, :at

	def initialize
		@at = Time.new
	end

	def pack (data)
		"#{type}#{" #{Protocol.encode(data)}" if data}\n"
	end
end

require 'torchat/protocol/standard'
require 'torchat/protocol/groupchat'

end; end
