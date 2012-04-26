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

require 'ostruct'

class Torchat; class Session

class Event
	attr_reader :session, :name

	def initialize (session, name, data = nil, &block)
		@session = session
		@name    = name

		@data = OpenStruct.new(data).tap(&block || proc {}).marshal_dump
	end

	def method_missing (id, *args)
		unless args.empty?
			raise ArgumentError, "wrong number of arguments (#{args.length} for 0)"
		end

		@data[id] if @data.has_key? id
	end

	def remove!;  @remove = true;  end
	def removed!; @remove = false; end
	def remove?;  @remove;         end

	def stop!;    @stop = true; end
	def stopped?; @stop;        end
end

end; end
