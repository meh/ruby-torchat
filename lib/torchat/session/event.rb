#--
# Copyleft meh. [http://meh.schizofreni.co | meh@schizofreni.co]
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
	class Removable
		attr_reader :session, :name, :chain, :block

		def initialize (session, name, chain = nil, &block)
			@session = session
			@name    = name
			@chain   = chain
			@block   = block
		end

		def removed?; @removed; end

		def remove!
			return if removed?

			@removed = true

			session.remove_callback(chain, name, block)
		end
	end

	attr_reader :session, :name

	def initialize (session, name, data = nil, &block)
		@session = session
		@name    = name

		@data = OpenStruct.new(data).tap(&block || proc {}).marshal_dump
	end

	def method_missing (id, *args)
		unless args.empty?
			raise ArgumentError, 'tried to pass parameters to an Event attribute'
		end

		@data[id] if @data.has_key? id
	end
	
	def respond_to_missing? (*)
		true
	end

	def remove!;  @remove = true;  end
	def removed!; @remove = false; end
	def remove?;  @remove;         end

	def stop!;    @stop = true; end
	def stopped?; @stop;        end

	def inspect
		"#<Torchat::Event(#{name}): #{@data.inspect}>"
	end
end

end; end
