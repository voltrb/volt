require 'volt/reactive/hash_dependency'

module Volt
  class ReactiveHash
    def initialize(values = {})
      @hash     = values
      @deps     = HashDependency.new
      @all_deps = Dependency.new
    end

    def ==(val)
      @all_deps.depend
      @hash == val
    end

    # TODO: We should finish off this class for reactivity
    def method_missing(method_name, *args, &block)
      @all_deps.depend

      @hash.send(method_name, *args, &block)
    end

    def [](key)
      @deps.depend(key)

      @hash[key]
    end

    def []=(key, value)
      @deps.changed!(key)
      @all_deps.changed!

      @hash[key] = value
    end

    def delete(key)
      @deps.delete(key)
      @all_deps.changed!
      @hash.delete(key)
    end

    def clear
      @hash.each_pair do |key, _|
        delete(key)
      end

      @all_deps.changed!
    end

    def replace(hash)
      clear

      hash.each_pair do |key, value|
        self[key] = value
      end
    end

    def to_h
      @all_deps.depend
      @hash
    end

    def inspect
      @all_deps.depend
      "#<ReactiveHash #{@hash.inspect}>"
    end
  end
end
