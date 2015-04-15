module Volt
  class LengthValidator
    def self.validate(model, field_name, args)
      errors = {}
      value  = model.get(field_name)

      if args.is_a?(Fixnum)
        min     = args
        max     = nil
        message = nil
      elsif args.is_a?(Hash)
        min = args[:length] || args[:minimum]
        max = args[:maximum]
        fail 'length or minimum must be specified' unless min.is_a?(Fixnum)

        message = args[:message]
      else
        fail 'The arguments to length must be a number or a hash'
      end

      if !value || value.size < min
        errors[field_name] = [message || "must be at least #{args} characters"]
      elsif max && value.size > max
        errors[field_name] = [message || "must be less than #{args} characters"]
      end

      errors
    end
  end
end
