require 'volt/models/persistors/base'

module Persistors
  class Store < Base
    def initialize(model, tasks=nil)
      @model = model
      @is_tracking = false
      @tasks = tasks
    end
    
    def loaded
      puts "Loaded: #{@model.inspect}"
      if @model.is_a?(ArrayModel)
        puts "Load Array Model: #{@model.class.inspect} at #{@model.path.inspect}"
        load_collection
      end
    end
    
    def query(query)
      puts "Find: #{@model.inspect}"
      @tasks.call('StoreTasks', 'find', @model.path.last, query) do |results|
        # TODO: Globals evil, replace
        $loading_models = true
        results.each do |result|
          puts "GOT: #{result.inspect} - #{@model.parent.inspect} - #{@model.path.inspect}"
          @model << Model.new(result, @model.options.merge(path: @model.path + [:[]]))
        end
        $loading_models = false
      end
    end
    
    def load_collection
      scope = {}
    
      # Scope to the parent
      if @model.path.size > 1 && (attrs = @model.attributes) && attrs[:_id].true?
        scope[:"#{path[-2].singularize}_id"] = _id
      end
      
      puts "Load At Scope: #{scope.inspect}"
      
      query(scope)
    end
    
    def changed(attribute_name)
      puts "Model Changed to: #{@model.attributes} on #{attribute_name}"
    end
    
    def added(model)
      puts "Added"
    end
    
    def event_added(event, scope_provider, first)
      if first && event == :changed
        
      end
    end
    
    def event_removed(event, no_more_events)
    end
    
    # On stores, we store the model so we don't have to look it up
    # every time we do a read.
    def read_new_model(method_name)
      # On stores, plural associations are automatically assumed to be
      # collections.
      options = @model.options.merge(parent: @model, path: @model.path + [method_name])
      if method_name.plural?
        model = @model.new_array_model([], options)
      else
        model = @model.new_model({}, options)
      end
    
      @model.attributes ||= {}
      @model.attributes[method_name] = model

      # if model.is_a?(StoreArray)# && model.state == :not_loaded
      #   model.load!
      # end
    
      return model
    end
  end
end