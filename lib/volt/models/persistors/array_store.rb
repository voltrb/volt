require 'volt/models/persistors/store'

module Persistors
  class ArrayStore < Store
    
    # Called when a collection loads
    def loaded
      scope = {}
    
    
    
      # Scope to the parent
      if @model.path.size > 1
        parent = @model.parent
        
        parent.persistor.ensure_setup if parent.persistor
        puts @model.parent.inspect
        
        if parent && (attrs = parent.attributes) && attrs[:_id].true?
          scope[:"#{@model.path[-3].singularize}_id"] = attrs[:_id]
        end
      end
      
      puts "Load At Scope: #{scope.inspect}"
      
      query(scope)
      
      change_channel_connection('add', 'added')
      change_channel_connection('add', 'removed')
    end
    
    def query(query)
      @tasks.call('StoreTasks', 'find', @model.path.last, query) do |results|
        # TODO: Globals evil, replace
        $loading_models = true
        
        new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)
        
        results.each do |result|
          @model << Model.new(result, new_options)
        end
        $loading_models = false
      end
    end
    
    def channel_name
      @model.path[-1]
    end
    
    
    # When a model is added to this collection, we call its "changed"
    # method.  This should trigger a save.
    def added(model)      
      unless $loading_models
        model.persistor.changed
      end
      
      if model.persistor
        # Tell the persistor it was added
        model.persistor.add_to_collection
      end
    end
    
    def removed(model)      
      if model.persistor
        # Tell the persistor it was removed
        model.persistor.remove_from_collection
      end
      
      if $loading_models
        return
      else
        puts "delete #{channel_name} - #{model.attributes[:_id]}"
        @tasks.call('StoreTasks', 'delete', channel_name, model.attributes[:_id])
      end
    end
    
  end
end