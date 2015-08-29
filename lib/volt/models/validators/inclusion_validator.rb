module Volt
  class InclusionValidator
    def self.validate(model, field_name, args)
      errors = {}
      value  = model.get(field_name)

      if args.is_a?(Array)
        list = args
        message = nil
      elsif args.is_a?(Hash)
        list = args[:in]
        message = args[:message]
        fail 'A list to match against must be specified' unless list.is_a?(Array)
      else
        fail 'The arguments to inclusion validator must be an array or a hash'
      end

      unless list.include?(value)
        errors[field_name] = [message || "must be one of #{list.join(', ')}"]
      end

      errors
    end
  end
end
