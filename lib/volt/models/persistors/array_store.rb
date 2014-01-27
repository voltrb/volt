require 'volt/models/persistors/store'

module Persistors
  class ArrayStore < Store
    
    # Called when a collection loads
    def loaded
      scope = {}
    
      # Scope to the parent
      if @model.path.size > 1 && (attrs = @model.attributes) && attrs[:_id].true?
        scope[:"#{path[-2].singularize}_id"] = _id
      end
      
      puts "Load At Scope: #{scope.inspect}"
      
      query(scope)
    end
    
    def query(query)
      @tasks.call('StoreTasks', 'find', @model.path.last, query) do |results|
        # TODO: Globals evil, replace
        $loading_models = true
        
        new_options = @model.options.merge(path: @model.path + [:[]])
        
        results.each do |result|
          @model << Model.new(result, new_options)
        end
        $loading_models = false
      end
    end
    
    def added(model)
      puts "Added"
    end
    
  end
end