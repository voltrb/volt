module ModelWrapper
  # For cretain values, we wrap them to make the behave as a
  # model.
  def wrap_value(value, lookup)
    if value.is_a?(Array)
      value = new_array_model(value, @options.merge(parent: self, path: path + lookup))
    elsif value.is_a?(Hash)
      value = new_model(value, @options.merge(parent: self, path: path + lookup))
    end

    return value
  end

  def wrap_values(values, lookup=[])
    if values.is_a?(Array)
      # Coming from an array
      values = values.map {|v| wrap_value(v,lookup + [:[]]) }
    elsif values.is_a?(Hash)
      pairs = values.map do |k,v|
        # TODO: We should be able to move wrapping into the method_missing on model
        path = lookup + [k.to_sym]

        [k, wrap_value(v,path)]
      end

      values = Hash[pairs]
    end

    return values
  end
end
