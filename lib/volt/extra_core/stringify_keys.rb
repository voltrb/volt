class Object
  def stringify_keys
    self.each_with_object({}) { |(key, value), hash|
      hash[key.to_s] = value
    }
  end
end