# Provides a method to setup a field on a model.
module FieldHelpers
  class InvalidFieldClass < RuntimeError; end

  NUMERIC_CAST = lambda do |convert_method, val|
    begin
      orig = val
      val = send(convert_method, val)

      if RUBY_PLATFORM == 'opal'
        # Opal has a bug in 0.7.2 that gives us back NaN without an
        # error sometimes.
        val = orig if val.nan?
      end
    rescue TypeError, ArgumentError => e
      # ignore, unmatched types will be caught below.
      val = orig
    end

    return val
  end

  FIELD_CASTS = {
    String     => :to_s.to_proc,
    Fixnum     => lambda {|val| NUMERIC_CAST[:Integer, val] },
    Numeric    => lambda {|val| NUMERIC_CAST[:Float, val] },
    Float      => lambda {|val| NUMERIC_CAST[:Float, val] },
    Time       => nil,
    TrueClass  => nil,
    FalseClass => nil
  }
  VALID_FIELD_CLASSES = FIELD_CASTS.keys


  module ClassMethods
    # field lets you declare your fields instead of using the underscore syntax.
    # An optional class restriction can be passed in.
    def field(name, klass = nil, auto_cast = true)
      if klass && !VALID_FIELD_CLASSES.include?(klass)
        klass_names = VALID_FIELD_CLASSES.map(&:to_s).join(', ')
        msg = "valid field types is currently limited to #{klass_names}"
        fail FieldHelpers::InvalidFieldClass, msg
      end

      if klass
        # Add type validation, execpt for String, since anything can be a string.
        unless klass == String
          validate name, type: klass
        end
      end

      define_method(name) do
        get(name)
      end

      define_method(:"#{name}=") do |val|
        # Check if the value assigned matches the class restriction
        if klass
          # Cast to the right type
          if (func = FIELD_CASTS[klass])
            val = func[val]
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
