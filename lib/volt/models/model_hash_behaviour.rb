module Volt
  # Contains all of the methods on a model that make it behave like a hash.
  # Moving this into a module cleans up the main Model class for things that
  # make it behave like a model.
  module ModelHashBehaviour

    def delete(name)
      name = name.to_sym

      value = attributes.delete(name)
      @deps.delete(name)

      @persistor.removed(name) if @persistor

      value
    end

    def nil?
      attributes.nil?
    end

    def empty?
      !attributes || attributes.size == 0
    end

    def false?
      attributes.false?
    end

    def true?
      attributes.true?
    end

    def clear
      attributes.each_pair do |key, value|
        @deps.changed!(key)
      end

      attributes.clear

      @persistor.removed(nil) if @persistor
    end

    def each_with_object(*args, &block)
      (@attributes || {}).each_with_object(*args, &block)
    end


    # Convert the model to a hash all of the way down.
    def to_h
      if empty?
        nil
      else
        hash = {}
        attributes.each_pair do |key, value|
          hash[key] = deep_unwrap(value)
        end
        hash
      end
    end
  end
end
