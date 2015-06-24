# Provides a method to setup a field on a model.
module FieldHelpers
  class InvalidFieldClass < RuntimeError; end

  module ClassMethods
    # field lets you declare your fields instead of using the underscore syntax.
    # An optional class restriction can be passed in.
    def field(name, klass = nil)
      if klass && ![String, Numeric].include?(klass)
        fail FieldHelpers::InvalidFieldClass, 'valid field types is currently limited to String or Numeric'
      end

      if klass
        # Add type validation, execpt for String, since anything can be a string.
        validate name, type: klass unless klass == String
      end

      define_method(name) do
        get(name)
      end

      define_method(:"#{name}=") do |val|
        # Check if the value assigned matches the class restriction
        if klass
          # Cast to the right type
          if klass == String
            val = val.to_s
          elsif klass == Numeric
            begin
              orig = val
              val = Float(val) unless val.is_a?(Numeric)

              if RUBY_PLATFORM == 'opal'
                # Opal has a bug in 0.7.2 that gives us back NaN without an
                # error sometimes.
                val = orig if val.nan?
              end
            rescue TypeError, ArgumentError => e
              # ignore, unmatched types will be caught below.
            end
          end
        end

        set(name, val)
      end
    end
  end

  def self.included(base)
    base.send :extend, ClassMethods
  end
end
