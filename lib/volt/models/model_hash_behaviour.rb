module Volt
  # Contains all of the methods on a model that make it behave like a hash.
  # Moving this into a module cleans up the main Model class for things that
  # make it behave like a model.
  module ModelHashBehaviour
    def delete(name)
      name = name.to_sym

      value = @attributes.delete(name)

      @size_dep.changed!
      @deps.delete(name)

      @persistor.removed(name) if @persistor

      value
    end

    def size
      @size_dep.depend
      @attributes.size
    end

    def keys
      @size_dep.depend
      @attributes.keys
    end

    def nil?
      @attributes.nil?
    end

    def empty?
      @size_dep.depend
      !@attributes || @attributes.size == 0
    end

    def false?
      @attributes.false?
    end

    def true?
      @attributes.true?
    end

    def clear
      @attributes.each_pair do |key, value|
        @deps.changed!(key)
      end

      @attributes.clear
      @size_dep.changed!

      @persistor.removed(nil) if @persistor
    end

    def each_with_object(*args, &block)
      (@attributes || {}).each_with_object(*args, &block)
    end

    def each_pair
      @attributes.each_pair do |k,v|
        yield(k,v)
      end
    end

    def key?(key)
      @attributes && @attributes.key?(key)
    end

    # Convert the model to a hash all of the way down.
    def to_h
      @size_dep.depend

      if @attributes.nil?
        nil
      else
        hash = {}
        @attributes.each_pair do |key, value|
          hash[key] = deep_unwrap(value)
        end
        hash
      end
    end

  end
end
