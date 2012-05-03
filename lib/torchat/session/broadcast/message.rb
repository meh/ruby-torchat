class Torchat; class Session; module Broadcast

class Message
	def self.parse (text)
		new text, text.scan(/#([^ ]+)/)
	end

	attr_reader :message, :tags

	def initialize (message, *tags)
		@message = message
		@tags    = tags.flatten.compact.uniq.map(&:to_sym)
	end

	def inspect
		"#<Torchat::Broadcast::Message(#{tags.join ' '}): #{message}>"
	end
end

end; end; end
