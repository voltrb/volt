require 'volt/models/persistors/store'
require 'volt/models/persistors/query/query_listener_pool'

module Persistors
  class ArrayStore < Store
    @@query_pool = QueryListenerPool.new
    
    attr_reader :model
    attr_accessor :state
    
    def self.query_pool
      @@query_pool
    end
    
    # Called when a collection loads
    def loaded
      @state = :not_loaded
      
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
    # rescue => e
    #   puts "ERROR: #{e.inspect}"
      
      # change_channel_connection('add', 'added')
      # change_channel_connection('add', 'removed')
    end

    # Called the first time data is requested from this collection
    def load_data
      if @state == :not_loaded
        @state = :loaded
        query_listener = @@query_pool.lookup(collection, query) do
          # Create if it does not exist
          QueryListener.new(self, @tasks, collection, query)
        end
        query_listener.add_store(self)
      end
    end
    
    # Called from backend
    def add(index, data)
      $loading_models = true
      
      new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)
      
      # Find the existing model, or create one
      new_model = @@identity_map.find(data['_id']) { Model.new(data.symbolize_keys, new_options) }
      
      @model.insert(index, new_model)
      
      $loading_models = false      
    end
    
    def remove(ids)
      $loading_models = true
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
      
      $loading_models = false
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