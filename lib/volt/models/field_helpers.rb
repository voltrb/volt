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
    String        => :to_s.to_proc,
    Fixnum        => lambda {|val| NUMERIC_CAST[:Integer, val] },
    Numeric       => lambda {|val| NUMERIC_CAST[:Float, val] },
    Float         => lambda {|val| NUMERIC_CAST[:Float, val] },
    Time          => nil,
    TrueClass     => nil,
    FalseClass    => nil,
    NilClass      => nil,
    Volt::Boolean => nil
  }


  module ClassMethods
    # field lets you declare your fields instead of using the underscore syntax.
    # An optional class restriction can be passed in.
    def field(name, klasses = nil, options = {})
      if klasses
        klasses = [klasses].flatten

        unless klasses.any? {|kl| FIELD_CASTS.key?(kl) }
          klass_names = FIELD_CASTS.keys.map(&:to_s).join(', ')
          msg = "valid field types is currently limited to #{klass_names}, you passed: #{klasses.inspect}"
          fail FieldHelpers::InvalidFieldClass, msg
        end

        # Add NilClass as an allowed type unless allow_nil: false was passed.
        unless options[:allow_nil] == false
          klasses << NilClass
        end
      end

      self.fields_data ||= {}
      self.fields_data[name] = [klasses, options]

      if klasses
        # Add type validation, execpt for String, since anything can be cast to
        # a string.
        unless klasses.include?(String)
          validate name, type: klasses
        end
      end

      define_method(name) do
        get(name)
      end

      define_method(:"#{name}=") do |val|
        # Check if the value assigned matches the class restriction
        if klasses
          # Cast to the right type
          klasses.each do |kl|
            if (func = FIELD_CASTS[kl])
              # Cast on the first available caster
              val = func[val]
              break
            end
          end
        end

        set(name, val)
      end
    end
  end

  def self.included(base)
    base.class_attribute :fields_data
    base.send :extend, ClassMethods
  end
end
