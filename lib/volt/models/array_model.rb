require 'volt/models/model_wrapper'

class ArrayModel < ReactiveArray
  include ModelWrapper
  
  attr_reader :parent, :path

  def initialize(array=[], parent=nil, path=nil)
    @parent = parent
    @path = path || []
    
    array = wrap_values(array)
    
    super(array)
  end
  
  def attributes
    self
  end
  
  # Make sure it gets wrapped
  def <<(*args)
    args = wrap_values(args)
    
    super(*args)
  end
  
  # Make sure it gets wrapped
  def inject(*args)
    args = wrap_values(args)
    super(*args)
  end

  # Make sure it gets wrapped
  def +(*args)
    args = wrap_values(args)
    super(*args)
  end
  
  def new_model(*args)
    Model.new(*args)
  end
  
  def new_array_model(*args)
    ArrayModel.new(*args)
  end
end