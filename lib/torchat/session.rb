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

require 'torchat/session/event'
require 'torchat/session/buddies'
require 'torchat/session/file_transfers'

class Torchat

class Session
	attr_reader   :config, :id, :name, :description, :status, :buddies, :file_transfers
	attr_writer   :client, :version
	attr_accessor :connection_timeout

	def initialize (config)
		@config = config

		@status = :offline

		@id          = @config['id'][/^(.*?)(\.onion)?$/, 1]
		@name        = config['name']
		@description = config['description']

		@buddies        = Buddies.new(self)
		@file_transfers = FileTransfers.new(self)

		@callbacks = Hash.new { |h, k| h[k] = [] }
		@before    = Hash.new { |h, k| h[k] = [] }
		@after     = Hash.new { |h, k| h[k] = [] }
		@timers    = []

		@connection_timeout = 60

		on :unknown do |e|
			e.buddy.send_packet :not_implemented, e.line.split(' ').first
		end

		on :verification do |e|
			# this actually gets executed only if the buddy doesn't exist
			# so we can still check if the buddy is permanent below
			buddies.add_temporary e.buddy

			e.buddy.send_packet :client,  client
			e.buddy.send_packet :version, version
			e.buddy.send_packet :supports, Protocol.extensions.map(&:name)

			e.buddy.send_packet :profile_name, name        if name
			e.buddy.send_packet :profile_text, description if description

			if e.buddy.permanent?
				e.buddy.send_packet :add_me
			end

			e.buddy.send_packet :status, status
		end

		on :supports do |e|
			e.buddy.supports *e.packet.to_a
		end

		on :status do |e|
			next if e.buddy.ready?

			e.buddy.ready!

			fire :ready, buddy: e.buddy
		end

		on :add_me do |e|
			e.buddy.permanent!
		end

		on :remove_me do |e|
			buddies.remove e.buddy

			e.buddy.disconnect
		end

		on :client do |e|
			e.buddy.client.name = e.packet.to_str
		end

		on :version do |e|
			e.buddy.client.version = e.packet.to_str
		end

		on :status do |e|
			e.buddy.status = e.packet.to_sym
		end

		on :profile_name do |e|
			e.buddy.name = e.packet.to_str
		end

		on :profile_text do |e|
			e.buddy.description = e.packet.to_str
		end

		on :profile_avatar_alpha do |e|
			e.buddy.avatar.alpha = e.packet.data
		end

		on :profile_avatar do |e|
			e.buddy.avatar.rgb = e.packet.data
		end

		on :filename do |packet, buddy|
			file_transfers.receive_file(packet.id, packet.name, packet.size, buddy)
		end

		on :filedata do |packet, buddy|
			next unless file_transfer = file_transfers[packet.id]

			if file_transfer.add_block(packet.offset, packet.data, packet.md5).valid?
				buddy.send_packet :filedata_ok, packet.id, packet.offset
			else
				buddy.send_packet :filedata_error, packet.id, packet.offset
			end
		end

		on :filedata_ok do |packet, buddy|

		end

		on :filedata_error do |packet, buddy|

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

				next if (Time.new.to_i - buddy.last_try.to_i) < ((buddy.tries > 36 ? 36 : buddy.tries) * 10)

				buddy.connect
			}
		end

		# typing extension support
		on :typing_start do |e|
			e.buddy.typing!

			fire :typing, buddy: e.buddy, mode: :start
		end

		on :typing_thinking do |e|
			e.buddy.thinking!

			fire :typing, buddy: e.buddy, mode: :thinking
		end

		on :typing_stop do |e|
			e.buddy.not_typing!

			fire :typing, buddy: e.buddy, mode: :stop
		end

		on :message do |e|
			next unless e.buddy.typing? || e.buddy.thinking?

			e.buddy.not_typing!

			fire :typing, buddy: e.buddy, mode: :stop
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

	def before (what = nil, &block)
		@before[what] << block
	end

	def after (what = nil, &block)
		@after[what] << block
	end

	def received (packet)
		fire packet.type, packet: packet, buddy: packet.from
	end

	def fire (name, data = nil, &block)
		name  = name.downcase.to_sym
		event = Event.new(self, name, data, &block)

		[@before[nil], @before[name], @callbacks[name], @after[name], @after[nil]].each {|callbacks|
			callbacks.each {|callback|
				begin
					callback.call event
				rescue => e
					Torchat.debug e
				end

				if event.remove?
					callbacks.delete(callback)
					event.removed!
				end
				
				return if event.stopped?
			}
		}
	end

	def start (host = nil, port = nil)
		host ||= @config['connection']['incoming']['host']
		port ||= @config['connection']['incoming']['port'].to_i

		@signature = EM.start_server host, port, Incoming do |incoming|
			incoming.instance_variable_set :@session, self
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
