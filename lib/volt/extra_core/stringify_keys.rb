class Object
  def stringify_keys
    each_with_object({}) do |(key, value), hash|
      hash[key.to_s] = value
    end
  end

  def symbolize_keys
    each_with_object({}) do |(key, value), hash|
      hash[key.to_sym] = value
    end
  end
end
