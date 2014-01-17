require 'volt/models/store_array'

class Store < Model
  ID_CHARS = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|v| v.to_a }.flatten
  
  @@identity_map = {}
  
  def initialize(tasks=nil, *args)
    @tasks = tasks

    super(*args)
    
    track_in_identity_map if attributes && attributes['_id']
    
    value_updated
  end

  def event_added(event, scope_provider, first)
    if first && event == :changed
      # Start listening
      $page.tasks.call('ChannelTasks', 'add_listener', 1)
    end
  end
  
  def event_removed(event, no_more_events)
    if no_more_events && event == :changed
      # Stop listening
      $page.tasks.call('ChannelTasks', 'remove_listener', 1)
    end
  end
  
  def self.update(model_id, data)
    model = @@identity_map[model_id]
    
    if model
      data.each_pair do |key, value|
        if key != '_id'
          puts "update #{key} with #{value.inspect}"
          model.send(:"#{key}=", value)
        end
      end
    end
  end
  
  def generate_id
    id = []
    12.times { id << ID_CHARS.sample }
    
    return id.join
  end
  
  def method_missing(method_name, *args, &block)
    result = super
    
    if method_name[0] == '_' && method_name[-1] == '='
      # Trigger value updated after an assignment
      self.value_updated
    end
    
    return result
  end
  
  def track_in_identity_map
    @@identity_map[attributes['_id']] = self
  end
  
  def value_updated
    # puts "VU: #{@tasks.inspect} = #{path.inspect} - #{attributes.inspect}"
    if (!defined?($loading_models) || !$loading_models) && @tasks && path.size > 0 && attributes.is_a?(Hash)
      
      # No id yet, lets create one
      unless attributes['_id']
        self.attributes['_id'] = generate_id
        track_in_identity_map
      end

      if parent && source = parent.parent
        # puts "FROM: #{path.inspect} - #{parent.inspect} && #{parent.parent.inspect}"
        self.attributes[path[-2].singularize+'_id'] = source._id
      end
      
      # Don't store any sub-stores, those will do their own saving.
      attrs = attributes.reject {|k,v| v.is_a?(Model) || v.is_a?(ArrayModel) }
      
      puts "Save: #{collection} - #{attrs.inspect}"
      @tasks.call('StoreTasks', 'save', collection, attrs)
    end
  end
  
  def collection(path=nil)
    path ||= self.path
    
    collection_name = path.last
    collection_name = path[-2] if collection_name == :[]
    
    return collection_name
  end
  
  # On stores, we store the model so we don't have to look it up
  # every time we do a read.
  def read_new_model(method_name)
    model = new_model(nil, self, path + [method_name])
    
    self.attributes ||= {}
    attributes[method_name] = model
    
    return model
  end
  
  
  
  def new_model(attributes={}, parent=nil, path=nil, class_paths=nil)
    model = Store.new(@tasks, attributes, parent, path, class_paths)

    if @tasks && path.last[-1] == 's'
      # puts "FIND NEW MODEL: #{path.inspect} - #{attributes.inspect}"
      
      # Check to see the parents scope so we can only lookup associated
      # models.
      scope = {}
      
      if parent._id.true?
        scope[path[-1].singularize + '_id'] = parent._id
      end
      
      @tasks.call('StoreTasks', 'find', collection(path), scope) do |results|
        # TODO: Globals evil, replace
        $loading_models = true
        results.each do |result|
          # Get model again, we need to fetch it each time so it gets the
          # updated model when it switches from nil.
          # TODO: Strange that this is needed
          model = self.send(path.last)
          model << Store.new(@tasks, result, model, path + [:[]], class_paths)
        end
        $loading_models = false
      end
    end
    
    return model
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end