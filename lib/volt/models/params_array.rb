class ParamsArray < ArrayModel
  def new_model(*args)
    Params.new(*args)
  end
  
  def new_array_model(*args)
    ParamsArray.new(*args)
  end
end