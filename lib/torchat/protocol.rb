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

		data.gsub!("\\", "\\/")
		data.gsub!("\n", "\\n")

		data
	end

	def self.decode (data)
		data = data.dup

		data.gsub!("\\n", "\n")
		data.gsub!("\\/", "\\")

		data
	end

	def self.unpack (data)
		name, data = data.split(' ', 2)

		Protocol.const_get(name.gsub(/(\A|_)(\w)/) { $2.upcase }).unpack(decode(data))
	end

	def self.from (from, data)
		unpack(data).tap { |p| p.from = from }
	end

	attr_accessor :from

	def pack (data)
		self.class.name[/(::)?([^:]+)$/, 2].gsub(/([A-Z])/) { $1.downcase }[1 .. -1] + Packet.encode(data)
	end
end

class NotImplemented < Packet
	def self.unpack (data)
		new(data)
	end

	attr_reader :command

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

	attr_reader :address, :cookie

	def initialize (address, cookie)
		@address = address
		@cookie  = cookie
	end

	def pack
		super("#{address} #{cookie}")
	end
end

end; end
