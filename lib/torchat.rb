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
require 'torchat/tor'

class Torchat
	def self.profile (name = nil)
		FileUtils.mkpath(directory = File.expand_path("~/.torchat#{"_#{name}" if name}"))

		new("#{directory}/torchat.ini").tap {|t|
			t.name = name
			t.path = directory
		}
	end

	attr_reader   :config, :session, :tor, :path
	attr_accessor :name

	def initialize (path)
		@config = if path.is_a? Hash
			path
		elsif path.end_with?('ini')
			ini = IniParse.parse(File.read(File.expand_path(path)))

			{
				'id'          => ini[:client][:own_hostname],
				'name'        => ini[:profile][:name],
				'description' => ini[:profile][:text],

				'connection' => {
					'outgoing' => {
						'host' => ini[:tor_portable][:tor_server],
						'port' => ini[:tor_portable][:tor_server_socks_port]
					},

					'incoming' => {
						'host' => ini[:client][:listen_interface],
						'port' => ini[:client][:listen_port]
					}
				}
			}
		else
			YAML.parse_file(path).transform
		end

		if @config['path']
			if @config['path'].is_a? String
				self.path = @config['path']
			else
				if @config['path']['buddy_list']
					buddy_list_at @config['path']['buddy_list']
				end

				if @config['path']['blocked_buddy_list']
					blocked_buddy_list_at @config['path']['blocked_buddy_list']
				end

				if @config['path']['offline_messages']
					offline_messages_at @config['path']['offline_messages']
				end
			end
		end

		@tor = Tor.new(@config)
	end

	def method_missing (id, *args, &block)
		return @session.__send__ id, *args, &block if @session.respond_to? id

		super
	end

	def respond_to_missing? (id, include_private = false)
		@session.respond_to? id, include_private
	end

	def start (&block)
		@session = Session.new(@config, &block)

		if @config['buddies']
			@config['buddies'].each {|id|
				@session.buddies.add(id)
			}
		end

		if @buddy_list && File.readable?(@buddy_list)
			File.open(@buddy_list).lines.each {|line|
				line.match(/^(.+?)(?: (.*?))?$/) {|m|
					next if m[1] == @session.id

					@session.buddies.add(m[1], m[2])
				}
			}
		end

		if @blocked_buddy_list && File.readable?(@blocked_buddy_list)
			File.open(@blocked_buddy_list).lines.each {|line|
				line.match(/^(.+?)(?: (.*?))?$/) {|m|
					next if m[1] == @session.id

					@session.buddies.add_temporary(m[1], m[2]).block!
				}
			}
		end

		if @offline_messages
			Dir["#@offline_messages/*_offline.txt"].each {|path|
				unless buddy = @session.buddies[path[/([^\/_]+)_offline\.txt$/, 1]]
					File.delete(path)

					next
				end

				File.open(path) {|f|
					current = ''

					until f.eof?
						line = f.readline
						
						if line.start_with? '[delayed] '
							buddy.messages.push current

							current = line[10 .. -1]
						else
							current << "\n" << line
						end
					end

					buddy.messages.push current unless current.empty?
				}

				File.delete(path)
			}
		end

		@session.start
	end

	def stop
		@session.stop
		@tor.stop

		if @buddy_list
			File.open(@buddy_list, 'w') {|f|
				@session.buddies.each {|id, buddy|
					next if buddy.temporary?

					f.puts "#{id} #{buddy.alias || buddy.name}"
				}
			}
		end

		if @blocked_buddy_list
			File.open(@blocked_buddy_list, 'w') {|f|
				@session.buddies.each {|id, buddy|
					next unless buddy.blocked?

					f.puts "#{id} #{buddy.alias || buddy.name}"
				}
			}
		end

		if @offline_messages
			@session.buddies.each {|id, buddy|
				next if buddy.messages.empty?

				File.open("#@offline_messages/#{id}_offline.txt") {|f|
					buddy.messages.each {|message|
						f.write "[delayed] #{message}\n"
					}
				}
			}
		end
	end

	def path= (directory)
		@path = directory

		unless @buddy_list
			buddy_list_at "#{directory}/buddy-list.txt"
		end

		unless @blocked_buddy_list
			blocked_buddy_list_at "#{directory}/blocked-buddy-list.txt"
		end

		unless @offline_messages
			offline_messages_at directory
		end
	end

	def buddy_list_at (path)
		@buddy_list = File.expand_path(path)
	end

	def blocked_buddy_list_at (path)
		@blocked_buddy_list = File.expand_path(path)
	end

	def offline_messages_at (path)
		@offline_messages = File.expand_path(path)
	end

	def send_packet_to (name, packet)
		@session.buddies[name].send_packet(packet)
	end

	def send_message_to (name, message)
		@session.buddies[name].send_message(message)
	end

	def send_broadcast (message)
		@session.broadcasts.send_message(message)
	end
end
