class LengthValidator
  def self.validate(model, field_name, args)
    errors = {}
    value = model.send(field_name)
    if !value || value.size < args
      errors[field_name] = ["must be at least #{args} chars"]
    end

    return errors
  end
end
