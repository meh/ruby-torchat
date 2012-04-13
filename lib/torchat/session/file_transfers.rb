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

require 'torchat/session/file_transfer'

class Torchat; class Session

class FileTransfers <  Hash
	attr_reader :session

	def initialize (session)
		@session = session
	end

	def receive_file (id, name, size, sender = nil)
		if has_key? id
			raise ArgumentError, 'file transfer with same id already exists'
		end
	end

	def send_file (buddy, path)

	end

	def send_blob (buddy, data)

	end

	def abort (id)
		unless file_transfer = self[id]
			raise ArgumentError, 'unexistent file transfer'
		end

		unless buddy = file_transfer.from || file_transfer.to
			raise ArgumentError, 'the file transfer is unstoppable, call Denzel Washington'
		end

		if file_transfer.from
			buddy.send_packet :file_stop_sending, id
		else
			buddy.send_packet :file_stop_receiving, id
		end

		delete(id)
	end
end

end; end
