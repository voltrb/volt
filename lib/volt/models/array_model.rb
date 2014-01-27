require 'volt/models/model_wrapper'

class ArrayModel < ReactiveArray
  include ModelWrapper
  
  attr_reader :parent, :path, :persistor

  def initialize(array=[], options={})
    @options = options
    @parent = options[:parent]
    @path = options[:path] || []
    @persistor = setup_persistor(options[:persistor])
    
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
    
    @persistor.added() if @persistor
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
  
  private
    # Takes the persistor if there is one and
    def setup_persistor(persistor)
      if persistor
        @persistor = persistor.new(self)
      end
    end
end