#! /usr/bin/env ruby
require 'optparse'
require 'torchat'

options = {}

OptionParser.new do |o|
	o.on '-p', '--profile PROFILE', 'the profile name' do |name|
		options[:profile] = name
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

		s.on :file_transfer_activity do |e|
			puts e.file_transfer.inspect
		end

		s.online!
	}
}
