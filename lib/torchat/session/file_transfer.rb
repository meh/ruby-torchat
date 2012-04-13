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
require 'forwardable'

require 'torchat/session/file_transfer/blocks'

class Torchat

class FileTransfer
	extend Forwardable

	attr_reader   :id, :name, :size, :blocks
	attr_accessor :from, :to

	alias length size

	def initialize (id = nil, name, size)
		@id   = id || Torchat.new_cookie
		@name = name
		@size = size

		@blocks = Blocks.new(self)
	end

	def finished?
		return false if @blocks.has_holes?

		@blocks.last.offset + @blocks.last.size >= size
	end

	def valid?
		@blocks.all?(&:valid?)
	end

	def add_block (*args)
		@blocks.add(*args)
	end

	def to_file
		raise ArgymentError, 'the transfer is not finished' unless finished?

		@blocks.to_file
	end

	def to_str
		raise ArgymentError, 'the transfer is not finished' unless finished?

		@blocks.to_str
	end
end

end
