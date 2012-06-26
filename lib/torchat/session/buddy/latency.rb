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

class Torchat; class Session; class Buddy

class Latency
	attr_reader :buddy

	def initialize (buddy)
		@buddy = buddy
	end

	def ping!
		@last_check = buddy.send_packet [:latency, :ping]
	end

	def pong (id)
		return unless id == @last_check.id

		@internal = Time.now - @last_check.at
	end

	def to_f
		unless @internal
			ping! unless @last_check

			return 0
		end

		@internal
	end

	def to_i
		to_f.to_i
	end
end

end; end; end
