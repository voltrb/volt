class LengthValidator
  def self.validate(model, field_name, args)
    errors = {}
    value = model.send(field_name)

    if args.is_a?(Fixnum)
      min = args
      max = nil
      message = nil
    else
      min = args[:length] || args[:min]
      max = args[:max]
      raise "length or min must be specified" unless min.is_a?(Fixnum)

      message = args[:message]
    end

    if !value || value.size < min
      errors[field_name] = [message || "must be at least #{args} characters"]
    elsif max && value.size > max
      errors[field_name] = [message || "must be less than #{args} characters"]
    end

    return errors
  end
end
