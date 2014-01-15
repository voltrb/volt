module ModelWrapper
  # For cretain values, we wrap them to make the behave as a
  # model.
  def wrap_value(value)
    if value.cur.is_a?(Array)
      value = ArrayModel.new(value, self, path + ['[]'])
    elsif value.cur.is_a?(Hash)
      value = Model.new(value, self, path + [:[]])
    end
    
    return value
  end
  
  def wrap_values(values)
    if values.cur.is_a?(Array)
      values = values.map {|v| wrap_value(v) }
    elsif values.cur.is_a?(Hash)
      values = Hash[values.map {|k,v| [k, wrap_value(v)] }]
    end
    
    return values
  end
end