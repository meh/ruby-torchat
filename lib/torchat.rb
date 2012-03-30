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

require 'yaml'
require 'iniparse'
require 'fileutils'

require 'torchat/version'
require 'torchat/utils'
require 'torchat/session'
require 'torchat/protocol'

class Torchat
	def self.profile (name = nil)
		FileUtils.mkpath(directory = "~/.torchat#{"_#{name}" if name}")

		new("#{directory}/torchat.ini").tap {|t|
			t.buddy_list_at "#{directory}/buddy-list.txt"
		}
	end

	attr_reader :config, :profile, :session

	def initialize (path, type = nil)
		if type == :ini || path.end_with?('ini')
			ini = IniParse.parse(File.read(File.expand_path(path)))

			@config = {}.tap {|config|
				config['address']     = ini[:client][:own_hostname]
				config['name']        = ini[:profile][:name]
				config['description'] = ini[:profile][:text]

				config['connection'] = {}.tap {|connection|
					connection['outgoing'] = {}.tap {|outgoing|
						outgoing['host'] = ini[:tor_portable][:tor_server]
						outgoing['port'] = ini[:tor_portable][:tor_server_socks_port]
					}

					connection['incoming'] = {}.tap {|incoming|
						incoming['host'] = ini[:client][:listen_interface]
						incoming['port'] = ini[:client][:listen_port]
					}
				}
			}
		elsif type == :yaml || path.end_with?('yml') || File.read(File.expand_path(path, 3)) == '---'
			@config = YAML.parse_file(path).transform
		end
	end

	def method_missing (id, *args, &block)
		return @session.__send__ id, *args, &block if @session.respond_to? id

		super
	end

	def respond_to_missing? (id)
		@session.respond_to? id
	end

	def start (&block)
		@session = Session.new(@config, &block)

		@session.start

		if @buddy_list
			File.read(@buddy_list).lines.each {|line|
				whole, id, name = line.match(/^(.*?) (.*?)$/).to_a

				if @config['buddies'] && @config['buddies'][id]
					@config['buddies'].delete(id)
				end

				@session.add_buddy id
			}
		end
	end

	def stop
		if @buddy_list
			@session.buddies.each {|buddy|
				next if @config['buddies'] && @config['buddies'][buddy.id]

				File.open(@buddy_list, 'w') {|f|
					f.puts "#{buddy.id} #{buddy.name}"
				}
			}
		end

		@session.stop
	end

	def buddy_list_at (path)
		@buddy_list = File.expand_path(path)
	end

	def send_packet_to (name, packet)
		@session.buddies[name].send_packet(packet)
	end

	def send_message_to (name, message)
		@session.buddies[name].send_message(message)
	end
end
