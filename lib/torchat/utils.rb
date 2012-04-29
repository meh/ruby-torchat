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

require 'securerandom'

class Torchat
	if ENV['DEBUG']
		require 'ap'
	end

	def self.debug (argument, options = {})
		return if !ENV['DEBUG'] && !options[:force]

		return if ENV['DEBUG'].to_i < (options[:level] || 1) && !options[:force]

		output = options[:prefix] ? options[:prefix] : "[#{Time.new}] "

		if argument.is_a?(Exception)
			output << "From: #{caller[0, options[:deep] || 1].join("\n")}\n"
			output << "#{argument.class}: #{argument.message}\n"
			output << argument.backtrace.collect {|stack|
				stack
			}.join("\n")
			output << "\n\n"
		elsif argument.is_a?(String)
			output << "#{argument}\n"
		else
			output << "#{argument.inspect}\n"
		end

		if options[:separator]
			output << options[:separator]
		end

		$stderr.puts output
	end

	def self.valid_address? (address)
		!!address.match(/^[234567abcdefghijklmnopqrstuvwxyz]{16}\.onion$/i)
	end

	def self.valid_id? (id)
		!!id.match(/^[234567abcdefghijklmnopqrstuvwxyz]{16}$/i)
	end

	def self.new_cookie
		SecureRandom.uuid
	end

	def self.normalize_id (value, return_nil = false)
		if value.respond_to? :id
			value = value.id
		end

		value = value.to_s[/^(.*?)(\.onion)?$/, 1]

		unless valid_id?(value)
			return if return_nil

			raise ArgumentError, 'the given ID is invalid'
		end

		value
	end
end
