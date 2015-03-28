require 'volt'

module Volt
  #Wrapper around a simple Hash for easy http header creation / manipulation
  class HttpResponseHeader < Hash
    def []=(key, value)
      super(key.to_s.headerize, value)
    end

    def [](key)
      super(key.to_s.headerize)
    end

    def delete(key)
      super(key.to_s.headerize)
    end

    def merge(other)
      self.dup.merge!(other)
    end

    def merge!(other)
      new_hash = {}
      other.each_with_object(new_hash) do |(key, value), hash|
        self[key.to_s.headerize] = value
      end
      self
    end
  end
end

