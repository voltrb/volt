require 'volt/models/persistors/store'
require 'volt/models/persistors/query/query_listener_pool'
require 'volt/models/persistors/store_state'

module Persistors
  class ArrayStore < Store
    include StoreState

    @@query_pool = QueryListenerPool.new

    attr_reader :model

    def self.query_pool
      @@query_pool
    end

    def initialize(model, tasks=nil)
      super

      @query = @model.options[:query]
    end

    def event_added(event, scope_provider, first, first_for_event)
      # First event, we load the data.
      load_data if first
    end

    def event_removed(event, last, last_for_event)
      # Remove listener where there are no more events on this model
      stop_listening if last
    end

    # Called when an event is removed and we no longer want to keep in
    # sync with the database.
    def stop_listening
      if @query_changed_listener
        @query_changed_listener.remove
        @query_changed_listener = nil
      end

      if @query_listener
        @query_listener.remove_store(self)
        @query_listener = nil
      end

      @state = :dirty
    end

    # Called the first time data is requested from this collection
    def load_data
      # Don't load data from any queried
      if @state == :not_loaded || @state == :dirty
        # puts "Load Data at #{@model.path.inspect} - query: #{@query.inspect}"# on #{@model.inspect}"
        change_state_to :loading

        @query_changed_listener.remove if @query_changed_listener
        if @query.reactive?
          # puts "SETUP REACTIVE QUERY LISTENER: #{@query.inspect}"
          # Query might change, change the query when it does
          @query_changed_listener = @query.on('changed') do
            stop_listening

            # Don't load again if all of the listeners are gone
            load_data if @model.has_listeners?
          end
        end

        run_query(@model, @query.deep_cur)
      end
    end

    # Clear out the models data, since we're not listening anymore.
    def unload_data
      change_state_to :not_loaded
      @model.clear
    end

    def run_query(model, query={})
      collection = model.path.last
      # Scope to the parent
      if model.path.size > 1
        parent = model.parent

        parent.persistor.ensure_setup if parent.persistor

        if parent && (attrs = parent.attributes) && attrs[:_id].true?
          query[:"#{model.path[-3].singularize}_id"] = attrs[:_id]
        end
      end

      @query_listener = @@query_pool.lookup(collection, query) do
        # Create if it does not exist
        QueryListener.new(@@query_pool, @tasks, collection, query)
      end

      @query_listener.add_store(self)
    end

    def find(query={})
      return Cursor.new([], @model.options.merge(:query => query))
    end

    # Returns a promise that is resolved/rejected when the query is complete.  Any
    # passed block will be passed to the promises then.  Then will be passed the model.
    def then(&block)
      promise = Promise.new

      promise = promise.then(&block) if block

      if @state == :loaded
        promise.resolve(@model)
      else
        @fetch_promises ||= []
        @fetch_promises << promise

        load_data
      end

      return promise
    end

    # Called from backend
    def add(index, data)
      $loading_models = true

      new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)

      # Don't add if the model is already in the ArrayModel
      if !@model.array.find {|v| v['_id'] == data['_id'] }
        # Find the existing model, or create one
        new_model = @@identity_map.find(data['_id']) { @model.new_model(data.symbolize_keys, new_options, :loaded) }

        @model.insert(index, new_model)
      end

      $loading_models = false
    end

    def remove(ids)
      $loading_models = true
      ids.each do |id|
        # TODO: optimize this delete so we don't need to loop
        @model.each_with_index do |model, index|
          if model._id == id
            del = @model.delete_at(index)
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
    def added(model, index)
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

      if defined?($loading_models) && $loading_models
        return
      else
        @tasks.call('StoreTasks', 'delete', channel_name, model.attributes[:_id])
      end
    end

  end
end
