if RUBY_PLATFORM == 'opal'
  module Volt
    module HtmlStorage

      # Implement in SessionStorage and LocalStorage
      def self.area
        raise 'should be implemented in SessionStorage or LocalStorage'
      end

      def self.[](key)
        `
          var val = {{store}}.getItem(key);
          return val === null ? nil : val;
        `
      end

      def self.[]=(key, value)
        `{{store}}.setItem(key, value)`
      end

      def self.clear
        `{{store}}.clear()`
        self
      end

      def self.delete(key)
        `
          var val = {{store}}.getItem(key);
          {{store}}.removeItem(key);
          return val === null ? nil : val;
        `
      end
    end
  end
else
  module Volt
    module HtmlStorage
      @@store = {}

      def self.[](key)
        @@store[key]
      end

      def self.[]=(key, value)
        @@store[key] = value
      end

      def self.clear
        @@store = {}

        self
      end

      def self.delete(key)
        @@store.delete(key)
      end
    end
  end
end
