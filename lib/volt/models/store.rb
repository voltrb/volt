require 'volt/models/store_array'

class Store < Model
  ID_CHARS = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|v| v.to_a }.flatten
  
  @@identity_map ||= {}
  
  def initialize(tasks=nil, *args)
    @tasks = tasks

    super(*args)
    
    value_updated
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
  
  def value_updated
    # puts "VU: #{@tasks.inspect} = #{path.inspect} - #{attributes.inspect}"
    if @tasks && path.size > 0 && attributes.is_a?(Hash)
      
      # No id yet, lets create one
      attributes['_id'] ||= generate_id

      
      if parent && source = parent.parent
        # puts "FROM: #{path.inspect} - #{parent.inspect} && #{parent.parent.inspect}"
        attributes[path[-2].singularize+'_id'] = source._id
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
    if @tasks
      # puts "FIND NEW MODEL: #{path.inspect} - #{attributes.inspect}"
      @tasks.call('StoreTasks', 'find', collection(path))
    end
    
    Store.new(@tasks, attributes, parent, path, class_paths)
  end
  
  def new_array_model(*args)
    StoreArray.new(@tasks, *args)
  end
end