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

require 'eventmachine'
require 'em-socksify'

require 'torchat/session/buddies'

class Torchat

class Session
	attr_reader :config, :buddies, :id, :name, :description, :status
	attr_writer :client, :version

	def initialize (config)
		@config = config

		@status = :available

		@id          = @config['id'][/^(.*?)(\.onion)?$/, 1]
		@name        = config['name']
		@description = config['description']

		@callbacks = Hash.new { |h, k| h[k] = [] }
		@buddies   = Buddies.new
		@timers    = []

		on :verification do |buddy|
			add_buddy buddy

			buddy.send_packet :client,  client
			buddy.send_packet :version, version

			buddy.send_packet :profile_name, name        if name
			buddy.send_packet :profile_text, description if description

			buddy.send_packet :add_me

			buddy.send_packet :status, status
		end

		on :add_me do |packet, buddy|
			fire :ready, buddy
		end

		on :remove_me do |packet, buddy|
			remove_buddy buddy
		end

		on :client do |packet, buddy|
			buddy.client.name = packet.to_str
		end

		on :version do |packet, buddy|
			buddy.client.version = packet.to_str
		end

		on :status do |packet, buddy|
			buddy.status = packet.to_sym
		end

		on :profile_name do |packet, buddy|
			buddy.name = packet.to_str unless packet.to_str.empty?
		end

		on :profile_text do |packet, buddy|
			buddy.description = packet.to_str unless packet.to_str.empty?
		end

		on :profile_avatar_alpha do |packet, buddy|
			buddy.avatar.alpha = packet.data
		end

		on :profile_avatar do |packet, buddy|
			buddy.avatar.rgb = packet.data
		end

		set_interval 120 do
			buddies.each_value {|buddy|
				buddy.send_packet :status, status
			}
		end

		yield self if block_given?
	end

	def address
		"#{id}.onion"
	end

	def client
		@client || 'ruby-torchat'
	end
	
	def version
		@version || Torchat.version
	end

	def tor
		Struct.new(:host, :port).new(
			@config['connection']['outgoing']['host'],
			@config['connection']['outgoing']['port'].to_i
		)
	end

	def name= (value)
		@name = value

		buddies.each_value {|buddy|
			buddy.send_packet :profile_name, value
		}
	end

	def description= (value)
		@description = value

		buddies.each_value {|buddy|
			buddy.send_packet :profile_text, value
		}
	end

	def status= (value)
		unless Protocol::Status.valid?(value)
			raise ArgumentError, "#{value} is not a valid status"
		end

		@status = value.to_sym.downcase

		buddies.each_value {|buddy|
			buddy.send_packet :status, @status
		}
	end

	def add_buddy (id)
		return if buddies.has_key? id

		buddy = if id.is_a? Buddy
			id
		else
			Buddy.new(self, id)
		end

		buddies << buddy
		buddy.connect

		buddy
	end

	def remove_buddy (id)
		return unless buddies.has_key? id

		buddy = if id.is_a? Buddy
			buddies.delete(buddies.key(id))
		else
			buddies.delete(id)
		end

		buddy.send_packet :remove_me
		buddy.disconnect

		buddy
	end

	def on (what, &block)
		@callbacks[what.to_sym.downcase] << block
	end

	alias when on

	def received (packet)
		fire packet.type, packet, packet.from
	end

	def fire (name, *args, &block)
		@callbacks[name.to_sym.downcase].each {|block|
			begin
				block.call *args, &block
			rescue => e
				Torchat.debug e
			end
		}
	end

	def start (host = nil, port = nil)
		host ||= @config['connection']['incoming']['host']
		port ||= @config['connection']['incoming']['port'].to_i

		@signature = EM.start_server host, port, Incoming do |incoming|
			incoming.instance_variable_set :@session, self

			fire :incoming, incoming
		end
	end

	def stop
		EM.stop_server @signature

		@timers.each {|timer|
			EM.cancel_timer(timer)
		}
	end

	def set_timeout (*args, &block)
		EM.schedule {
			EM.add_timer(*args, &block).tap {|timer|
				@timers.push(timer)
			}
		}
	end

	def set_interval (*args, &block)
		EM.schedule {
			EM.add_periodic_timer(*args, &block).tap {|timer|
				@timers.push(timer)
			}
		}
	end

	def clear_timeout (what)
		EM.schedule {
			EM.cancel_timer(what)
		}
	end

	alias clear_interval clear_timeout
end

end
