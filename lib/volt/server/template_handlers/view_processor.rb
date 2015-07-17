module Volt
  class ViewProcessor
    def self.cache_key
      @cache_key ||= "#{name}:0.1".freeze
    end

    def self.call(input)
      data = input[:data]

      input[:cache].fetch([self.cache_key, data]) do
        # Remove all semicolons from source
        input[:data]
      end
    end
  end
end

Sprockets.register_transformer 'text/html', 'application/ruby', Volt::ViewProcessor