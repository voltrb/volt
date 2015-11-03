module Volt
  class Location
    def host
      if RUBY_PLATFORM == 'opal'
        `document.location.host`
      else
        Volt.config.domain
      end
    end

    def protocol
      scheme + ':'
    end

    def scheme
      if RUBY_PLATFORM == 'opal'
        `document.location.protocol`[0..-2]
      else
        Volt.config.scheme || 'http'
      end
    end
  end
end
