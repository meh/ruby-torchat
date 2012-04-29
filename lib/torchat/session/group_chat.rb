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

require 'forwardable'

class Torchat; class Session

class GroupChat
	attr_reader :session, :id, :modes, :participants

	def initialize (session, id, *modes)
		@session = session
		@id      = id
		@modes   = modes.flatten.uniq.compact.map(&:to_sym)

		@participants = Participants.new(self)
		@joining      = true
	end

	def method_missing (id, *args, &block)
		return @participants.__send__ id, *args, &block if @participants.respond_to? id

		super
	end

	def respond_to_missing? (id, include_private = false)
		@participants.respond_to? id, include_private
	end

	def joining?; @joining;         end
	def joined?;  !joining?;        end
	def joined!;  @joining = false; end

	def on (what, &block)
		session.on what do |e|
			block.call e if e.group_chat == self
		end
	end

	def invited_by (value = nil)
		raise ArgumentError, 'cannot overwrite the invitor' if @invited_by && value

		value ? @invited_by = value : @invited_by
	end

	def invited?
		!!invited_by
	end

	def invite (buddy)
		return unless buddy = session.buddies[buddy]

		return unless buddy.online?

		return if participants.find { |p| p.id == buddy.id }

		buddy.send_packet [:groupchat, :invite], id, modes
		buddy.send_packet [:groupchat, :participants], id, participants.keys

		self
	end

	def left?; @left; end

	def leave (reason = nil)
		return if left?

		@left = true

		participants.each_value {|buddy|
			buddy.send_packet [:groupchat, :leave], id, reason
		}

		session.group_chats.destroy id
	end

	def send_message (message)
		participants.each_value {|buddy|
			buddy.send_packet [:groupchat, :message], id, message
		}
	end

	def inspect
		"#<Torchat::GroupChat(#{id})#{"[#{modes.join ' '}]" unless modes.empty?}: #{empty? ? 'empty' : map(&:id).join(' ')}>"
	end
end

end; end

require 'torchat/session/group_chat/participants'
