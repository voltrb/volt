class StoreArray < ArrayModel
  def initialize(tasks=nil, array=[], parent=nil, path=nil)
    @tasks = tasks

    super(array, parent, path)
  end
  
  def event_added(event, scope_provider, first) 
    puts "New event: #{event.inspect} - #{first}"   
    if event == :added && first
      # Start listening for added items on the collection
      
      change_channel_connection('add')
    end
  end
  
  def change_channel_connection(add_or_remove)
    if parent.attributes && path.size != 0
      channel_name = "#{path[-1]}"
      puts "Listen on #{channel_name}"
      @tasks.call('ChannelTasks', "#{add_or_remove}_listener", channel_name)
    end    
  end
  
  def new_model(*args)
    Store.new(@tasks, *args)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end