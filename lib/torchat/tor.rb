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

class Torchat

class Tor
	class Instance < EM::Connection
		def receive_data (data)
			return unless ENV['DEBUG'] && ENV['DEBUG'].to_i >= 5

			print data.gsub(/^/, 'tor] ')
		end

		alias stop close_connection

		def unbind
			@owner.error unless get_status.success?
		end
	end

	attr_reader   :config
	attr_accessor :file

	def initialize (config)
		@config = config

		@file = 'torrc'
	end

	def start (path, *args, &block)
		return if @instance

		if block
			@error = args.shift
		end

		block    = args.shift
		@error ||= args.shift

		File.expand_path(path).tap {|path|
			FileUtils.mkpath path

			Dir.chdir path do
				unless File.exists?(@file)
					File.open(@file, 'w') { |f| f.print rc }
				end

				EM.popen "tor -f '#@file'", Instance do |t|
					@instance = t

					t.instance_variable_set :@owner, self
				end

				block.arity.zero? ? block.call : block.call(path) if block
			end
		}
	end

	def stop
		return unless @instance

		@instance.close_connection
	end

	def error
		@error.call if @error
	end

	def rc
		<<-EOF.gsub /^\t+/, ''
			SocksPort #{config['connection']['outgoing']['port']}

			HiddenServiceDir hidden_service
			HiddenServicePort 11009 #{
				config['connection']['incoming']['host']
			}:#{
				config['connection']['incoming']['port']
			}

			DataDirectory tor_data

			AvoidDiskWrites 1
			LongLivedPorts 11009
			FetchDirInfoEarly 1
			CircuitBuildTimeout 30
			NumEntryGuards 6
		EOF
	end
end

end
