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

require 'stringio'

require 'torchat/session/file_transfer'

class Torchat; class Session

class FileTransfers <  Hash
	attr_reader :session

	def initialize (session)
		@session = session
	end

	def receive (id, name, size, sender = nil)
		if has_key? id
			raise ArgumentError, 'file transfer with same id already exists'
		end

		self[id] = FileTransfer.new(id, name, size).tap {|ft|
			ft.from = sender
		}
	end

	def send_file (buddy, path)
		unless File.readable?(path)
			raise ArgumentError, "#{path} is unreadable"
		end

		FileTransfer.new(self, File.basename(path), File.size(path)).tap {|ft|
			ft.to    = buddy
			ft.input = File.open(path)

			self[ft.id] = ft

			ft.next_block.tap {|block|
				buddy.send_packet :filedata, ft.id, block.offset, block.data, block.md5
			}
		}
	end

	def send_blob (buddy, data, name = Torchat.new_cookie)
		self[id] = FileTransfer.new(self, name, data.size).tap {|ft|
			ft.to    = buddy
			ft.input = StringIO.new(data)

			self[ft.id] = ft

			ft.next_block.tap {|block|
				buddy.send_packet :filedata, ft.id, block.offset, block.data, block.md5
			}
		}
	end

	def abort (id)
		unless file_transfer = self[id]
			raise ArgumentError, 'unexistent file transfer'
		end

		delete(file_transfer.abort.id)
	end
end

end; end
