if RUBY_PLATFORM == 'opal'
  module Volt
    module LocalStorage
      def self.[](key)
        `
          var val = localStorage.getItem(key);
          return val === null ? nil : val;
        `
      end

      def self.[]=(key, value)
        `localStorage.setItem(key, value)`
      end

      def self.clear
        `localStorage.clear()`
        self
      end

      def self.delete(key)
        `
          var val = localStorage.getItem(key);
          localStorage.removeItem(key);
          return val === null ? nil : val;
        `
      end
    end
  end
else
  module Volt
    module LocalStorage
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
