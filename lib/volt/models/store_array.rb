class StoreArray < ArrayModel
  def initialize(tasks=nil, array=[], parent=nil, path=nil)
    @tasks = tasks

    super(array, parent, path)
  end
  
  def event_added(event, scope_provider, first)
    super
    
    puts "event added: #{event} - #{first}"
  end
  
  def new_model(*args)
    Store.new(@tasks, *args)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end