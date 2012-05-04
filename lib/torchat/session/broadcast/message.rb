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

class Torchat; class Session; module Broadcast

class Message
	def self.parse (text)
		new text, text.scan(/#([^ ]+)/)
	end

	attr_reader :at, :tags

	def initialize (message, *tags)
		@at       = Time.new
		@internal = message
		@tags     = tags.flatten.compact.uniq.map(&:to_sym)
	end

	def to_s
		@internal
	end

	alias to_str to_s

	def == (other)
		to_s == other
	end

	def inspect
		"#<Torchat::Broadcast::Message(#{tags.join ' '}): #{to_s}>"
	end
end

end; end; end
