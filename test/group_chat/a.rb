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
		s.when :connecting_to do |e|
			Torchat.debug "connecting to #{e.address}:#{e.port}"
		end

		s.on :failed_connection do |e|
			Torchat.debug "#{e.buddy.id} failed to connect"
		end

		s.on :connection do |e|
			Torchat.debug "#{e.buddy.id} connected"
		end

		s.on :verification do |e|
			Torchat.debug "#{e.buddy.id} has been verified"
		end

		s.on :disconnection do |e|
			Torchat.debug "#{e.buddy.id} disconnected"
		end

		s.online!
	}
}
