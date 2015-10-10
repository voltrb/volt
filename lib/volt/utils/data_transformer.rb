# DataTransformer is a singleton class that walks ruby data structures (nested
# hashes, arrays, etc..) and lets you transform them based on values or keys
#
# NOTE: DataTransformer is not automatically required, but can be when needed.

module Volt
  class DataTransformer
    # Takes a hash or array, and nested map's over the values, yielding to
    # the block the value.  The return value from the block replaces the
    # previous value.
    # NOTE: This does not yield hashes or arrays.
    def self.transform(data, &block)
      if data.is_a?(Hash)
        data.map do |key, value|
          key = transform(key, &block)
          value = transform(value, &block)
          [key, value]
        end.to_h
      elsif data.is_a?(Array)
        data.map do |value|
          transform(value, &block)
        end
      else
        # yield to the trasnformer
        yield(data)
      end
    end

    # Like #transform, except it only yields keys.
    def self.transform_keys(data, &block)
      if data.is_a?(Hash)
        data.map do |key, value|
          key = transform_keys(key, &block)
          value = transform_keys(value, &block)

          # map the key
          [yield(key), value]
        end.to_h
      elsif data.is_a?(Array)
        data.map do |value|
          transform_keys(value, &block)
        end
      else
        # no mapping
        data
      end
    end
  end
end
