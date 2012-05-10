#! /usr/bin/env ruby
require 'optparse'
require 'torchat'

options = {}

OptionParser.new do |o|
	o.on '-p', '--profile PROFILE', 'the profile name' do |name|
		options[:profile] = name
	end

	o.on '-i', '--invite NAME...', Array, 'list of names to invite' do |name|
		options[:invite] = name
	end
end.parse!

EM.run {
	Torchat.profile(options[:profile]).start {|s|
		s.when :connect_to do |e|
			Torchat.debug "connecting to #{e.address}:#{e.port}"
		end

		s.on :connect_failure do |e|
			Torchat.debug "#{e.buddy.id} failed to connect"
		end

		s.on :connect do |e|
			Torchat.debug "#{e.buddy.id} connected"
		end

		s.on :verify do |e|
			Torchat.debug "#{e.buddy.id} has been verified"
		end

		s.on :disconnect do |e|
			Torchat.debug "#{e.buddy.id} disconnected"
		end

		s.group_chats.create.tap {|gc|
			gc.on :group_chat_join do |e|
				gc.send_message "yo #{e.buddy.id}"

				s.set_interval 10 do
					gc.send_message '^_^'
				end
			end

			options[:invite].each {|id|
				s.buddies.add_temporary(id).on :ready do |e|
					gc.invite(e.buddy)
				end
			}
		}

		s.online!
	}
}
