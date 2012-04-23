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

class Torchat; class Session

class Event
	class DSL < BasicObject
		def initialize (&block)
			@data = {}

			instance_eval &block
		end

		def method_missing (id, value)
			@data[id] = value
		end

		def to_hash
			@data
		end
	end

	attr_reader :session, :name

	def initialize (session, name, &block)
		@session = session
		@name    = name

		@data = DSL.new(&block).to_hash
	end

	def method_missing (id)
		@data[id] if @data.has_key? id
	end

	def remove!;  @remove = true;  end
	def removed!; @remove = false; end
	def remove?;  @remove;         end

	def stop!;    @stop = true; end
	def stopped?; @stop;        end
end

end; end
