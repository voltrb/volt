require 'volt'

module Volt
  # Wrapper around a Hash for easy http header creation / manipulation with
  # indifferent access.
  # header[:content_type] == header['Content-Type'] ==
  # header['content-type'] == header ['Content_Type']
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
      dup.merge!(other)
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
