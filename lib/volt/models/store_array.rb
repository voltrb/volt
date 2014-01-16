class StoreArray < ArrayModel
  def new_model(*args)
    Store.new(*args)
  end
  
  def new_array_model(*args)
    StoreArray.new(*args)
  end
end