module ModelHelpers
  def deep_unwrap(value)
    if value.is_a?(Model)
      value = value.to_h
    elsif value.is_a?(ArrayModel)
      value = value.to_a
    end
    
    return value
  end
end