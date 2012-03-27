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

require 'torchat/server/buddy'

class Torchat

class Server
	attr_reader :options, :buddies

	def initialize (options)
		@options = options

		@callbacks = Hash.new { |h, k| h[k] = [] }
		@buddies   = []
		@timers    = []

		yield self if block_given?
	end

	def add_buddy (address, ali = nil)
		Buddy.new(self, address).tap {|buddy|
			buddy.alias = ali
		}
	end

	def on (what, &block)
		@callbacks[what] << block
	end

	def received (packet)
		@callbacks[packet.type].each {|block|
			block.call(packet, packet.from)
		}
	end

	def fire (name, *args, &block)
		@callbacks[name].each {|block|
			block.call *args, &block
		}
	end

	def start (host = '0.0.0.0', port)
		zelf = self

		@signature = EM.start_server host, port, Incoming do |incoming|
			incoming.instance_eval { @server = zelf }
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
