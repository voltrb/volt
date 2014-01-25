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
  
  def self.from_id(id)
    @@identity_map[id]
  end

  def event_added(event, scope_provider, first)
    if first && event == :changed
      # Start listening
      ensure_id
      change_channel_connection("add")
    end
  end
  
  def event_removed(event, no_more_events)
    if no_more_events && event == :changed
      # Stop listening
      change_channel_connection("remove")
    end
  end
  
  def change_channel_connection(add_or_remove)
    if attributes && path.size > 1
      channel_name = "#{path[-2]}##{attributes[:_id]}"
      puts "Event Added: #{channel_name} -- #{attributes.inspect}"
      @tasks.call('ChannelTasks', "#{add_or_remove}_listener", channel_name)
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
    path_size = path.size
    if !(defined?($loading_models) && $loading_models) && @tasks && path_size > 0 && !nil?
      
      ensure_id
      
      if path_size > 3 && parent && source = parent.parent
        self.attributes[:"#{path[-4].singularize}_id"] = source._id
      end
      
      # puts "Save: #{collection} - #{attrs.inspect}"
      @tasks.call('StoreTasks', 'save', collection, self_attributes)
    end
  end
  
  # Return the attributes that are only for this store, not any sub-associations.
  def self_attributes
    # Don't store any sub-stores, those will do their own saving.
    attrs = attributes.reject {|k,v| v.is_a?(Model) || v.is_a?(ArrayModel) }    
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
    # On stores, plural associations are automatically assumed to be
    # collections.
    if method_name.plural?
      model = new_array_model([], self, path + [method_name])
    else
      model = new_model(nil, self, path + [method_name])
    end
    
    self.attributes ||= {}
    attributes[method_name] = model
    
    if model.is_a?(StoreArray)# && model.state == :not_loaded
      model.load!
    end
    
    return model
  end

  
  # When called, this model is deleted from its current parent collection
  # and from the database
  def delete!
    if path.size == 0
      raise "Not in a collection"
    end
    
    # TEMP: Find this model in the parent's collection
    parent.each_with_index do |child,index|
      puts "CHECK #{child.inspect} vs #{self.inspect}"
      if child._id == self._id
        puts "FOUND AT: #{index}"
        parent.delete_at(index)
        break
      end
    end

    # Send to the DB that we got deleted
    unless $loading_models
      puts "delete #{collection} - #{attributes[:_id]}"
      @tasks.call('StoreTasks', 'delete', collection, attributes[:_id])
    end
  end
  
  def inspect
    "<#{self.class.to_s}-#{@state} #{attributes.inspect}>"
  end
  
  def new_model(attributes={}, parent=nil, path=nil, class_paths=nil)
    return Store.new(@tasks, attributes, parent, path, class_paths)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end