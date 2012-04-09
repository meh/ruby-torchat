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

class Torchat; class FileTransfer

class Block
	attr_reader :owner, :data, :md5

	def initialize (owner, offset, data, md5 = nil)
		@owner  = owner
		@offset = offset
		@data   = data.force_encoding('BINARY')
		@md5    = md5 || Digest::MD5.hexdigest(data)
	end

	def size
		@size || @data.bytesize
	end

	alias length size

	def valid?
		Digest::MD5.hexdigest(data) == md5
	end

	def to_s
		@data
	end

	alias to_str to_s
end

end; end
