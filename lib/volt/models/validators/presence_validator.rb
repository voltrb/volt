class PresenceValidator
  def self.validate(model, field_name, args)
    errors = {}
    value = model.send(field_name)
    if !value || value.blank?
      errors[field_name] = ["must be specified"]
    end

    return errors
  end
end
