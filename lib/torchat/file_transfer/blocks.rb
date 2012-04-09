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

class Blocks < Array
	attr_reader :file_transfer

	def initialize (file_transfer)
		@file_transfer = file_transfer
	end

	def add_block (offset, data, md5 = nil)
		Block.new(self, offset, data, md5).tap {|block|
			push block
			sort_by!(&:offset)
		}
	end

	def has_holes?
		!!map { |b| [b.offset, b.size] }.reduce {|res, cur|
			break unless res

			cur if ((res.first + res.last) >= cur.first)
		}
	end

	def to_file

	end

	def to_str
	end
end

end; end
