module Volt
  module Parsing
    def self.decodeURI(value)
      if RUBY_PLATFORM == 'opal'
        `decodeURI(value)`
      else
        CGI.unescape(value.to_s)
      end
    end

    def self.encodeURI(value)
      if RUBY_PLATFORM == 'opal'
        `encodeURI(value)`
      else
        CGI.escape(value.to_s)
      end
    end
  end
end
