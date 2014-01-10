require 'volt/models/model_wrapper'

class ArrayModel < ReactiveArray
  include ModelWrapper

  def initialize(array=[], parent=nil, path=nil)
    @parent = parent
    @path = path
    
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
end