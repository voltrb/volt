module Volt
  class PresenceValidator
    def self.validate(model, old_model, field_name, args)
      errors = {}
      value  = model.read_attribute(field_name)
      if !value || value.blank?
        if args.is_a?(Hash) && args[:message]
          message = args[:message]
        else
          message = 'must be specified'
        end

        errors[field_name] = [message]
      end

      errors
    end
  end
end
