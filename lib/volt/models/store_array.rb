class StoreArray < ArrayModel
  attr_reader :state
  
  def initialize(tasks=nil, array=[], parent=nil, path=nil)
    @tasks = tasks
    @state = :not_loaded

    super(array, parent, path)
    
    # TEMP: TODO: Setup the listeners right away
    change_channel_connection('add', 'added')
    change_channel_connection('add', 'removed')
  end
  
  # def event_added(event, scope_provider, first) 
  #   puts "New event1: #{event.inspect} - #{first}"   
  #   if first && [:added, :removed].include?(event)
  #     # Start listening for added items on the collection
  #     
  #     change_channel_connection('add', event)
  #   end
  # end
  # 
  # def event_removed(event, no_more_events)
  #   if no_more_events && [:added, :removed].include?(event)
  #     # Stop listening
  #     change_channel_connection("remove", event)
  #   end
  # end
  
  
  def load!
    if @state == :not_loaded
      @state = :loading
    
      if @tasks && path.last.plural?
        # Check to see the parents scope so we can only lookup associated
        # models.
        scope = {}
      
        # Scope to the parent
        if path.size > 1 && attributes && attributes[:_id].true?
          scope[:"#{path[-2].singularize}_id"] = _id
        end
        
        puts "Load At Scope: #{scope.inspect}"
        
        load_child_models(scope)
      end
    end
    
    return self
  end
  
  def load_child_models(scope)
    # puts "FIND: #{collection(path).inspect} at #{scope.inspect}"
    @tasks.call('StoreTasks', 'find', path.last, scope) do |results|
      # TODO: Globals evil, replace
      $loading_models = true
      results.each do |result|
        self << Store.new(@tasks, result, self, path + [:[]], @class_paths)
      end
      $loading_models = false
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