class Object
  def stringify_keys
    self.each_with_object({}) { |(key, value), hash|
      hash[key.to_s] = value
    }
  end

  def symbolize_keys
    self.each_with_object({}) { |(key, value), hash|
      hash[key.to_sym] = value
    }
  end
end