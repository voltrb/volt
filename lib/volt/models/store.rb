require 'volt/models/store_array'

class Store < Model
  ID_CHARS = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|v| v.to_a }.flatten
  
  @@identity_map = {}
  
  attr_reader :state
  
  def initialize(tasks=nil, *args)
    @tasks = tasks
    @state = :not_loaded

    super(*args)
    
    track_in_identity_map if attributes && attributes[:_id]
    
    value_updated
  end

  def event_added(event, scope_provider, first)
    if first && event == :changed
      # Start listening
      ensure_id
      if self.attributes && self.path.size > 1
        channel_name = "#{self.path[-2]}##{self.attributes[:_id]}"
        $page.tasks.call('ChannelTasks', 'add_listener', channel_name)
      end
    end
  end
  
  def event_removed(event, no_more_events)
    if no_more_events && event == :changed
      # Stop listening
      if self.attributes && self.path.size > 1
        channel_name = "#{self.path[-2]}##{self.attributes[:_id]}"
        $page.tasks.call('ChannelTasks', 'remove_listener', channel_name)
      end
    end
  end
  
  def self.update(model_id, data)
    model = @@identity_map[model_id]
    
    if model
      data.each_pair do |key, value|
        if key != '_id'
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
    if method_name[-1] == ']'
      # Load the model
      self.load!
    end

    result = super
    
    if method_name[0] == '_' && method_name[-1] == '='
      # Trigger value updated after an assignment
      self.value_updated
    end
    
    return result
  end
  
  def track_in_identity_map
    @@identity_map[attributes[:_id]] = self
  end
  
  # When called, will setup an id if there is not one
  def ensure_id
    # No id yet, lets create one
    if attributes && !attributes[:_id]
      self.attributes[:_id] = generate_id
      track_in_identity_map
    end
  end
  
  def value_updated
    if (!defined?($loading_models) || !$loading_models) && @tasks && path.size > 0 && !self.nil?
      
      ensure_id
      
      if path.size > 3 && parent && source = parent.parent
        self.attributes[(path[-4].to_s.singularize+'_id').to_sym] = source._id
      end
      
      # Don't store any sub-stores, those will do their own saving.
      attrs = attributes.reject {|k,v| v.is_a?(Model) || v.is_a?(ArrayModel) }
      
      # puts "Save: #{collection} - #{attrs.inspect}"
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
    
    if model.state == :not_loaded
      # model.load!
    end
    
    return model
  end
  
  def load!
    if @state == :not_loaded
    
      @state = :loading
    
      if @tasks && path.last[-1] == 's'
        # Check to see the parents scope so we can only lookup associated
        # models.
        scope = {}
      
        # Scope to the parent
        if path.size > 2 && parent.attributes && parent.attributes[:_id].true?
          scope[(path[-3].to_s.singularize + '_id').to_sym] = parent._id
        end
        
        load_child_models(scope)
      end
    end
    
    return self
  end
  
  def load_child_models(scope)
    # puts "FIND: #{collection(path).inspect} at #{scope.inspect}"
    @tasks.call('StoreTasks', 'find', collection(path), scope) do |results|
      # TODO: Globals evil, replace
      $loading_models = true
      results.each do |result|
        self << Store.new(@tasks, result, self, path + [:[]], @class_paths)
      end
      $loading_models = false
    end
  end
  
  def new_model(attributes={}, parent=nil, path=nil, class_paths=nil)
    return Store.new(@tasks, attributes, parent, path, class_paths)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end