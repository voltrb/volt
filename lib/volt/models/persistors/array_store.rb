require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'
require 'volt/models/persistors/query/normalizer'
require 'volt/models/persistors/query/query_listener_pool'
require 'volt/utils/timers'

module Volt
  module Persistors
    class ArrayStore < Store
      include StoreState

      @@query_pool = QueryListenerPool.new

      attr_reader :model, :root_dep

      def self.query_pool
        @@query_pool
      end

      def initialize(model, tasks = nil)
        super

        # The listener event counter keeps track of how many things are listening
        # on this model and loads/unloads data when in use.
        @listener_event_counter = EventCounter.new(
          -> { load_data },
          -> { stop_listening }
        )

        # The root dependency tracks how many listeners are on the ArrayModel
        # @root_dep = Dependency.new(@listener_event_counter.method(:add), @listener_event_counter.method(:remove))
        @root_dep = Dependency.new(method(:listener_added), method(:listener_removed))

        @query = @model.options[:query]
      end

      def loaded(initial_state = nil)
        super

        # Setup up the query listener, and if it is already listening, then
        # go ahead and load that data in.  This allows us to use it immediately
        # if the data is loaded in another place.
        if query_listener.listening
          query_listener.add_store(self)
          @added_to_query = true
        end
      end

      def inspect
        "<#{self.class.to_s}:#{object_id} #{@model.path.inspect} #{@query.inspect}>"
      end

      # Called when an each binding is listening
      def event_added(event, first, first_for_event)
        # First event, we load the data.
        if first
          @listener_event_counter.add
        end
      end

      # Called when an each binding stops listening
      def event_removed(event, last, last_for_event)
        # Remove listener where there are no more events on this model
        if last
          @listener_event_counter.remove
        end
      end

      # Called by child models to track their listeners
      def listener_added
        @listener_event_counter.add
        # puts "LIST ADDED: #{inspect} - #{@listener_event_counter.count} #{@model.path.inspect}"
      end

      # Called by child models to track their listeners
      def listener_removed
        @listener_event_counter.remove
        # puts "LIST REMOVED: #{inspect} - #{@query.inspect} - #{@listener_event_counter.count} #{@model.path.inspect}"
      end

      # Called when an event is removed and we no longer want to keep in
      # sync with the database.  The data is kept in memory and the model's
      # loaded_state is marked as "dirty" meaning it may not be in sync.
      def stop_listening
        # puts "Stop LIST1"
        Timers.next_tick do
          Computation.run_without_tracking do
            # puts "STOP LIST2"
            if @listener_event_counter.count == 0
              if @added_to_query
                @query_listener.remove_store(self)
                @query_listener = nil

                @added_to_query = nil
              end

              @model.change_state_to(:loaded_state, :dirty)
            end
          end
        end

        Timers.flush_next_tick_timers! if Volt.server?
      end

      # Called the first time data is requested from this collection
      def load_data
        # puts "LOAD DATA: #{@model.path.inspect}: #{@model.options[:query].inspect}"
        Computation.run_without_tracking do
          loaded_state = @model.loaded_state

          # Don't load data from any queried
          if loaded_state == :not_loaded || loaded_state == :dirty
            @model.change_state_to(:loaded_state, :loading)

            run_query
          end
        end
      end

      def run_query
        unless @added_to_query
          @model.clear

          @added_to_query = true
          query_listener.add_store(self)
        end
      end

      # Looks up the query listener for this ArrayStore
      # @query should be treated as immutable.
      def query_listener
        return @query_listener if @query_listener

        collection = @model.path.last
        query = @query

        # Scope to the parent
        if @model.path.size > 1
          parent = @model.parent

          parent.persistor.ensure_setup if parent.persistor

          if parent && (attrs = parent.attributes) && attrs[:_id].true?
            query = query.dup

            query << [:find, {:"#{@model.path[-3].singularize}_id" => attrs[:_id]}]
          end
        end

        query = Query::Normalizer.normalize(query)

        @query_listener ||= @@query_pool.lookup(collection, query) do
          # Create if it does not exist
          QueryListener.new(@@query_pool, @tasks, collection, query)
        end

        # @@query_pool.print

        @query_listener
      end

      # Find takes a query object
      def where(query = nil)
        query ||= {}

        add_query_part(:find, query)
      end
      alias_method :find, :where

      def limit(limit)
        add_query_part(:limit, limit)
      end

      def skip(skip)
        add_query_part(:skip, skip)
      end

      # .sort is already a ruby method, so we use order instead
      def order(sort)
        add_query_part(:sort, sort)
      end

      # Add query part adds a [method_name, *arguments] array to the query.
      # This will then be passed to the backend to run the query.
      #
      # @return [Cursor] a new cursor
      def add_query_part(*args)
        opts = @model.options
        query = opts[:query] ? opts[:query].deep_clone : []
        query << args

        # Make a new opts hash with changed query
        opts = opts.merge(query: query)
        Cursor.new([], opts)
      end

      # Returns a promise that is resolved/rejected when the query is complete.  Any
      # passed block will be passed to the promises then.  Then will be passed the model.
      def fetch(&block)
        promise = Promise.new

        # Run the block after resolve if a block is passed in
        promise = promise.then(&block) if block

        if @model.loaded_state == :loaded
          promise.resolve(@model)
        else
          Proc.new do |comp|
            if @model.loaded_state == :loaded
              promise.resolve(@model)

              comp.stop
            end

          end.watch!
        end

        promise
      end

      # Alias then for now
      # TODO: Deprecate
      alias_method :then, :fetch

      # Called from backend
      def add(index, data)
        $loading_models = true

        Model.no_validate do
          data_id = data['_id'] || data[:_id]

          # Don't add if the model is already in the ArrayModel
          unless @model.array.find { |v| v._id == data_id }
            # Find the existing model, or create one
            new_model = @@identity_map.find(data_id) do
              new_options = @model.options.merge(path: @model.path + [:[]], parent: @model)
              @model.new_model(data, new_options, :loaded)
            end

            @model.insert(index, new_model)
          end
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
          # Tell the persistor it was added, return the promise
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
          StoreTasks.delete(channel_name, model.attributes[:_id])
        end
      end
    end
  end
end
