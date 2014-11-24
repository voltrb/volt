module Volt
  class NumericalityValidator
    def self.validate(model, old_model, field_name, args)
      errors = {}

      value = model.read_attribute(field_name)
      value = Kernel.Float(value) if value !~ /\A0[xX]/

      errors[field_name] = []
      if value && value.is_a?(Numeric)
        if args.is_a?(Hash)

          args.each do |arg, val|
            case arg
            when :min
              if value < args[:min]
               errors[field_name] << 'number must be greater than ' + args[:min].to_s
              end
            when :max
              if value > args[:min]
                errors[field_name] << 'number must be less than ' + args[:max].to_s
              end
            end
          end

        end
      else
        if args.is_a?(Hash) && args[:message]
          errors[field_name] << args[:message]
        else
          errors[field_name] << 'must be numeric'
        end
      end

      errors
    end
  end
end
