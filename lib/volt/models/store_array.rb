class StoreArray < ArrayModel
  def initialize(tasks=nil, array=[], parent=nil, path=nil)
    @tasks = tasks

    super(array, parent, path)
  end
  
  def event_added(event, scope_provider, first) 
    puts "New event1: #{event.inspect} - #{first}"   
    if first && [:added, :removed].include?(event)
      # Start listening for added items on the collection
      
      change_channel_connection('add', event)
    end
  end
  
  def event_removed(event, no_more_events)
    if no_more_events && [:added, :removed].include?(event)
      # Stop listening
      change_channel_connection("remove", event)
    end
  end
  
  
  def change_channel_connection(add_or_remove, event)
    if parent.attributes && path.size != 0
      channel_name = "#{path[-1]}-#{event}"
      puts "Listen on #{channel_name} - #{add_or_remove}"
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