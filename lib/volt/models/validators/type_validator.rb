# Enforces a type on a field.  Typically setup from ```field :name, Type```
module Volt
  class TypeValidator
    def self.validate(model, field_name, args)
      errors = {}
      value  = model.get(field_name)

      type_restriction = args.is_a?(Hash) ? args[:type] : args

      unless value.is_a?(type_restriction)
        if args.is_a?(Hash) && args[:message]
          message = args[:message]
        else
          message = "must be of type #{type_restriction.to_s}"
        end

        errors[field_name] = [message]
      end

      errors
    end
  end
end
