module Volt
  class PresenceValidator
    def self.validate(model, field_name, args)
      errors = {}
      value  = model.get(field_name)
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
