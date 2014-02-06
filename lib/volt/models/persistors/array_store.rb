require 'volt/models/persistors/store'
require 'volt/models/persistors/query/query_listener_pool'

module Persistors
  class ArrayStore < Store
    @@query_pool = QueryListenerPool.new
    
    attr_reader :model
    
    def self.query_pool
      @@query_pool
    end
    
    # Called when a collection loads
    def loaded
      query = {}
      collection = @model.path.last
    
      # Scope to the parent
      if @model.path.size > 1
        parent = @model.parent
        
        parent.persistor.ensure_setup if parent.persistor
        puts @model.parent.inspect
        
        if parent && (attrs = parent.attributes) && attrs[:_id].true?
          query[:"#{@model.path[-3].singularize}_id"] = attrs[:_id]
        end
      end
      
      query_listener = @@query_pool.lookup(collection, query)
      query_listener.add_store(self)
    rescue => e
      puts "ERROR: #{e.inspect}"
      
      # change_channel_connection('add', 'added')
      # change_channel_connection('add', 'removed')
    end

    # Called from the backend when new results for this query arrive.
    def self.updated(collection, query, data)
      # TODO: Normalize query
      
      stored_collection = @@live_queries[collection]
      if stored_collection
        model_persistors = stored_collection[query]
        
        if model_persistors
          model_persistors.each do |model_persistor|
            model_persistor.update(data)
          end
        end
      end
    end
    
    def update(data)
      # TODO: Globals evil, replace
      $loading_models = true
      
      new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)
      
      @model.clear
      data.each do |result|
        @model << Model.new(result, new_options)
      end
      $loading_models = false
    end
    
    # Called from backend
    def add(index, data)
      $loading_models = true
      
      new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)
      
      @model.insert(index, Model.new(data, new_options))
      # @model << Model.new(data, new_options)
      
      puts "====" + @model.inspect
      $loading_models = false      
    end
    
    def remove(ids)
      puts "Removed"
      ids.each do |id|
        puts "delete at: #{id} on #{@model.inspect}"
        
        # TODO: optimize this delete so we don't need to loop
        @model.each_with_index do |model, index|
          if model._id == id
            @model.delete_at(index)
            break
          end
        end
      end
    end
    
    def channel_name
      @model.path[-1]
    end
    
    
    # When a model is added to this collection, we call its "changed"
    # method.  This should trigger a save.
    def added(model)
      unless defined?($loading_models) && $loading_models
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