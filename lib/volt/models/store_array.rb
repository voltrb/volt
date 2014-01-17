class StoreArray < ArrayModel
  def initialize(tasks=nil, load_from_saved=false, array=[], parent=nil, path=nil)
    @tasks = tasks

    super(array, parent, path)
  end
  
  def new_model(*args)
    Store.new(@tasks, false, *args)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, false, *args)
  end
end