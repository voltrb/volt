require 'volt/models/store_array'

class Store < Model
  def method_missing(method_name, *args, &block)
    result = super
    
    if method_name[0] == '_' && method_name[-1] == '='
      # Trigger value updated after an assignment
      self.value_updated
    end
    
    return result
  end
  
  def value_updated
    puts "VALUE UPD: #{self.inspect}"
  end
  
  
  def new_model(*args)
    Store.new(*args)
  end
  
  def new_array_model(*args)
    StoreArray.new(*args)
  end
end