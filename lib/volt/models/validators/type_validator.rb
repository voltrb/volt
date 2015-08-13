# Enforces a type on a field.  Typically setup from ```field :name, Type```
module Volt
  # Volt::Boolean can be used if you want a boolean type
  class Boolean
  end

  class TypeValidator
    def self.validate(model, field_name, args)
      errors = {}
      value  = model.get(field_name)

      type_restriction = args.is_a?(Hash) ? (args[:type] || args[:types]) : args

      # Make into an array of 1 if its not already an array.
      type_restrictions = [type_restriction].flatten

      valid_type = false
      type_restrictions.each do |type_rest|
        if value.is_a?(type_rest)
          valid_type = true
          break
        end
      end

      unless valid_type
        if args.is_a?(Hash) && args[:message]
          message = args[:message]
        else
          type_msgs = type_restrictions.map do |type_rest|
            if [Fixnum, Float, Numeric].include?(type_rest)
              "a number"
            elsif type_rest == NilClass
              # we don't mention the nil restriction
              nil
            elsif type_rest == Volt::Boolean
              ['true', 'false']
            elsif type_rest == TrueClass
              'true'
            elsif type_rest == FalseClass
              'false'
            else
              "a #{type_rest.to_s}"
            end
          end.flatten

          message = "must be #{type_msgs.compact.to_sentence(conjunction: 'or')}"
        end

        errors[field_name] = [message]
      end

      errors
    end
  end
end
