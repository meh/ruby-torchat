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

require 'torchat/session/file_transfer/block'

class Torchat

class FileTransfer
	extend Forwardable

	attr_reader   :file_transfers, :id, :name, :size, :output, :input
	attr_accessor :from, :to, :block_size

	alias length size

	def initialize (file_transfers = nil, name, size)
		@file_transfers = file_transfers
		@id             = id || Torchat.new_cookie
		@name           = name @size           = size
		@block_size     = 4096
	end

	def outgoing?
		!!to
	end

	def incoming?
		!!from
	end

	def input= (io)
		raise ArgumentError, 'you cannot change input' if @input && @input != io

		@input = io
	end

	def output= (io)
		raise ArgumentError, 'you cannot change output' if @output && @output != io

		@output = io

		@cache.each {|block|
			output.seek(block.offset)
			output.write(block.data)
		}

		@cache = nil
	end

	def tell
		if @input
			@input.tell
		elsif @output
			@output.size
		elsif @cache
			block = @cache.max { |a, b| a.offset <=> b.offset }

			block.offset + block.size
		else
			0
		end
	end

	def completion
		tell.to_f / size * 100
	end

	def finished?
		io.size >= size
	end

	def add_block (offset, data, md5 = nil)
		Block.new(self, offset, data, md5).tap {|block|
			raise ArgumentError, 'the data is invalid' unless block.valid?

			if output
				output.seek(offset)
				output.write(data)
			else
				(@cache ||= []) << block
			end
		}
	end

	def next_block
		raise 'there is no input' unless input

		@last = Block.new(self, input.tell, input.read(block_size))
	end

	def last_block
		raise 'there is no input' unless input

		@last = Block.new(self, input.tell, input.read(block_size))
	end

	def abort
		if incoming?
			from.send_packet :file_stop_sending, id
		elsif outgoing?
			to.send_packet :file_stop_receiving, id
		else
			raise ArgumentError, 'the file transfer is unstoppable, call Denzel Washington'
		end

		file_transfers.delete(id) if file_transfers

		self
	end
end

end
