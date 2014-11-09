# Use a volt model to persist to cookies.
# Some code borrowed from: https://github.com/opal/opal-browser/blob/master/opal/browser/cookies.rb

require 'volt/models/persistors/base'

module Volt
  module Persistors
    # Backs a collection in the local store
    class Cookies < Base
      def read_cookies
        cookies = `document.cookie`
        Hash[cookies.split(';').map do |v|
          parts = v.split('=').map { |p| p = p.strip ; `decodeURIComponent(p)` }

          # Default to empty if no value
          parts << '' if parts.size == 1

          parts
        end]
      end

      def write_cookie(key, value, options={})
        parts = []

        parts << `encodeURIComponent(key)`
        parts << '='
        parts << `encodeURIComponent(value)`
        parts << '; '

        parts << 'max-age=' << options[:max_age] << '; '        if options[:max_age]
        if options[:expires]
          expires = options[:expires]
          parts << 'expires=' << `expires.toGMTString()` << '; '
        end
        parts << 'path='    << options[:path] << '; '           if options[:path]
        parts << 'domain='  << options[:domain] << '; '         if options[:domain]
        parts << 'secure'                                       if options[:secure]

        cookie_val = parts.join

        `document.cookie = cookie_val`
      end

      def initialize(model)
        @model = model
      end

      # Called when a model is added to the collection
      def added(model, index)
        # Save an added cookie
      end

      def loaded(initial_state = nil)
        # When the main model is first loaded, we pull in the data from the
        # store if it exists
        if !@loaded && @model.path == []
          @loaded = true

          writing_cookies do
            read_cookies.each_pair do |key, value|
              @model.assign_attribute(key, value)
            end
          end
        end
      end

      # Callled when an cookies value is changed
      def changed(attribute_name)
        # TODO: Make sure we're only assigning directly, not sub models
        unless $writing_cookies
          value = @model.read_attribute(attribute_name)

          # Temp, expire in 1 year, going to expand this api
          write_cookie(attribute_name, value.to_s, expires: Time.now + (356 * 24 * 60 * 60))
        end
      end

      def removed(attribute_name)
        writing_cookies do
          write_cookie(attribute_name, '', expires: Time.now)
        end
      end

      def writing_cookies
        $writing_cookies = true
        yield
        $writing_cookies = false
      end
    end
  end
end
