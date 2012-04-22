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
require 'torchat/session/groupchats'

class Torchat

class Session
	attr_reader   :config, :id, :name, :description, :status, :buddies, :groupchats
	attr_writer   :client, :version
	attr_accessor :connection_timeout

	def initialize (config)
		@config = config

		@status = :offline

		@id          = @config['id'][/^(.*?)(\.onion)?$/, 1]
		@name        = config['name']
		@description = config['description']

		@buddies    = Buddies.new(self)
		@groupchats = GroupChats.new(self)

		@callbacks = Hash.new { |h, k| h[k] = [] }
		@timers    = []

		@connection_timeout = 60

		# standard protocol implementation
		on :unknown do |line, buddy|
			buddy.send_packet :not_implemented, line.split(' ').first
		end

		on :verification do |buddy|
			# this actually gets executed only if the buddy doesn't exist
			# so we can still check if the buddy is permanent below
			buddies.add_temporary buddy

			buddy.send_packet :client,  client
			buddy.send_packet :version, version
			buddy.send_packet :supports, Protocol.extensions.map(&:name)

			buddy.send_packet :profile_name, name        if name
			buddy.send_packet :profile_text, description if description

			if buddy.permanent?
				buddy.send_packet :add_me
			end

			buddy.send_packet :status, status
		end

		on :supports do |packet, buddy|
			buddy.supports *packet.to_a
		end

		on :status do |packet, buddy|
			next if buddy.ready?

			buddy.ready!

			fire :ready, buddy
		end

		on :add_me do |packet, buddy|
			buddy.permanent!
		end

		on :remove_me do |packet, buddy|
			buddies.remove buddy
			buddy.disconnect
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
			buddy.name = packet.to_str
		end

		on :profile_text do |packet, buddy|
			buddy.description = packet.to_str
		end

		on :profile_avatar_alpha do |packet, buddy|
			buddy.avatar.alpha = packet.data
		end

		on :profile_avatar do |packet, buddy|
			buddy.avatar.rgb = packet.data
		end

		set_interval 120 do
			next unless online?

			buddies.each_value {|buddy|
				next unless buddy.online?

				if (Time.new.to_i - buddy.last_received.at.to_i) >= 360
					buddy.disconnect
				else
					buddy.send_packet :status, status
				end
			}
		end

		set_interval 10 do
			next unless online?

			buddies.each_value {|buddy|
				next if buddy.online? || buddy.blocked?

				next if (Time.new.to_i - buddy.last_try.to_i) < (buddy.tries * 10)

				buddy.connect
			}
		end

		# typing extension support
		on :typing_start do |packet, buddy|
			buddy.typing!

			fire :typing, buddy, :start
		end

		on :typing_thinking do |packet, buddy|
			buddy.thinking!

			fire :typing, buddy, :thinking
		end

		on :typing_stop do |packet, buddy|
			buddy.not_typing!

			fire :typing, buddy, :stop
		end

		on :message do |packet, buddy|
			buddy.not_typing!

			fire :typing, buddy, :stop
		end

		# groupchat implementation
		on :groupchat_invite do |packet, buddy|
			return if groupchats.has_key? packet.id

			groupchats.create(packet.id).invited!
		end

		on :groupchat_participants do |packet, buddy|
			return unless groupchats.has_key? packet.id

			if packet.any? { |p| buddies[p] && buddies[p].blocked? }
				buddy.send_packet [:groupchat, :leave], packet.id
			else
				buddy.send_packet [:groupchat, :join], packet.id

				packet.each {|p|
					buddy = buddies.add_temporary(p)

					buddy.on :verification do
						buddy.send_packet 
					end

					groupchats[packet.id].participants.push buddy
				}

				fire :joined, groupchats[packet.id]
			end
		end

		on :groupchat_invited do |packet, buddy|
			return unless groupchats.has_key? packet.id

			groupchats[packet.id].add(packet.to_s)
		end

		on :disconnection do |buddy|
			groupchats.each_value {|groupchat|
				groupchat.delete(buddy)
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

	def online?;  @status != :offline; end
	def offline?; !online?;            end

	def online!
		return if online?

		@status = :available

		buddies.each_value {|buddy|
			buddy.connect
		}
	end

	def offline!
		return if offline?

		@status = :offline

		buddies.each_value {|buddy|
			buddy.disconnect
		}
	end

	def status= (value)
		if value.to_sym.downcase == :offline
			offline!; return
		end

		online! if offline?

		unless Protocol[:status].valid?(value)
			raise ArgumentError, "#{value} is not a valid status"
		end

		@status = value.to_sym.downcase

		buddies.each_value {|buddy|
			buddy.send_packet :status, @status
		}
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

			if offline?
				incoming.close_connection

				next
			end
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
