# Provides a method to setup a field on a model.
module FieldHelpers
  class InvalidFieldClass < RuntimeError ; end

  module ClassMethods
    # field lets you declare your fields instead of using the underscore syntax.
    # An optional class restriction can be passed in.
    def field(name, klass=nil)
      if klass && ![String, Numeric].include?(klass)
        raise FieldHelpers::InvalidFieldClass, "valid field types is currently limited to String or Numeric"
      end

      define_method(name) do
        read_attribute(name)
      end

      define_method(:"#{name}=") do |val|
        # Check if the value assigned matches the class restriction
        if klass
          # Cast to the right type
          if klass == String
            val = val.to_s
          elsif klass == Numeric
            val = val.to_f
          end
        end

        assign_attribute(name, val)
      end
    end
  end

  def self.included(base)
    base.send :extend, ClassMethods
  end

end