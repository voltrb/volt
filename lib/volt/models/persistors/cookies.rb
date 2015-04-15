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
          # Equals are valid as part of a cookie, so only parse the first equals.
          parts = v.split('=', 2).map { |p| p = p.strip; `decodeURIComponent(p)` }

          # Default to empty if no value
          parts << '' if parts.size == 1

          # Equals are valid in
          parts
        end]
      end

      def write_cookie(key, value, options = {})
        options[:path] ||= '/'
        parts = []

        parts << `encodeURIComponent(key)`
        parts << '='
        parts << `encodeURIComponent(value)`
        parts << '; '

        parts << 'path='    << options[:path] << '; '           if options[:path]
        parts << 'max-age=' << options[:max_age] << '; '        if options[:max_age]

        if (expires = options[:expires])
          parts << 'expires=' << `expires.toGMTString()` << '; '
        end

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
        if !@cookies_loaded && @model.path == []
          @cookies_loaded = true

          writing_cookies do
            # Assign directly so we don't trigger the callbacks on the initial load
            attrs = @model.attributes

            read_cookies.each_pair do |key, value|
              attrs[key.to_sym] = value
            end
          end
        end
      end

      # Callled when an cookies value is changed
      def changed(attribute_name)
        # TODO: Make sure we're only assigning directly, not sub models
        unless $writing_cookies
          value = @model.get(attribute_name)

          # Temp, expire in 1 year, going to expand this api
          write_cookie(attribute_name, value.to_s, expires: Time.now + (356 * 24 * 60 * 60), path: '/')
        end
      end

      def removed(attribute_name)
        writing_cookies do
          write_cookie(attribute_name, '', max_age: 0, path: '/')
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
