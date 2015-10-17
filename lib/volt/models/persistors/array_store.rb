require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'
require 'volt/models/persistors/query/query_listener_pool'
require 'volt/models/persistors/query/query_identifier'
require 'volt/utils/timers'

module Volt
  module Persistors
    class ArrayStore < Store
      include StoreState
      include ReactiveAccessors

      @@query_pool = QueryListenerPool.new

      attr_reader :model, :root_dep

      def self.query_pool
        @@query_pool
      end

      def initialize(model, tasks = nil)
        # Keep a hash of all ids in this collection
        @ids = {}

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
        "<#{self.class}:#{object_id} #{@model.path.inspect} #{@query.inspect}>"
      end

      # Called when an each binding is listening
      def event_added(event, first, first_for_event)
        # First event, we load the data.
        @listener_event_counter.add if first
      end

      # Called when an each binding stops listening
      def event_removed(event, last, last_for_event)
        # Remove listener where there are no more events on this model
        @listener_event_counter.remove if last
      end

      # Called by child models to track their listeners
      def listener_added
        @listener_event_counter.add
      end

      # Called by child models to track their listeners
      def listener_removed
        # puts "LIST REMOVE:  #{inspect}"
        @listener_event_counter.remove
      end

      # Called when an event is removed and we no longer want to keep in
      # sync with the database.  The data is kept in memory and the model's
      # loaded_state is marked as "dirty" meaning it may not be in sync.
      def stop_listening
        Timers.client_set_timeout(5000) do
          Computation.run_without_tracking do
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

          if parent && !@model.is_a?(Cursor) && (attrs = parent.attributes) && attrs[:id]
            query = query.dup

            query << [:where, { :"#{@model.path[-3].singularize}_id" => attrs[:id] }]
          end
        end

        query = Volt::DataStore.adaptor_client.normalize_query(query)

        @query_listener ||= @@query_pool.lookup(collection, query) do
          # Create if it does not exist
          QueryListener.new(@@query_pool, @tasks, collection, query)
        end

        # @@query_pool.print

        @query_listener
      end

      # Add query part adds a [method_name, *arguments] array to the query.
      # This will then be passed to the backend to run the query.
      #
      # @return [Cursor] a new cursor
      def add_query_part(*args, &block)
        opts = @model.options
        query = opts[:query] ? opts[:query].deep_clone : []

        if args[0] == :where && block
          # Change the query name to show that we were passed a block
          args[0] = :where_with_block
          # Block was passed to where query, pass in the QueryIdentifier
          result = block.call(QueryIdentifier.new)

          query << [*args, result.to_query]
        else
          query << args
        end

        # Make a new opts hash with changed query
        opts = opts.merge(query: query)
        Cursor.new([], opts)
      end

      # When doing things like .count, we get back a value, not an Array of
      # Models.  To handle this, the updates from the server just resolve the
      # value directly.
      def resolve_value(val)
        if @resolve_promises
          # Resolve all waiting promises
          resolve_promises.each do |promise|
            promise.resolve(val)
          end
        else
          # Only invalidate to generate a new promise if the previous one is
          #  already realized.
          resolve_dep.changed!
          @resolve_dep = nil
        end

        # @root_dep.changed!

        @model.value = val
        @resolve_promises = nil
      end

      def value
        # proc do |comp|
        @root_dep.depend
        resolve_dep.depend
        #   comp.stop
        # end.watch!
        unless Computation.current
          # Load the data now manually not running inside of a computation.
          load_data
        end

        if @value.respond_to?(:has_value?) && @model.has_value? && (resval = self.resolved_value)
          # Value is already there, return a resolved promise
          return Promise.new.resolve(resval)
        else
          # Otherwise generate a new promise and queue it for resolving
          promise = Promise.new
          resolve_promises << promise

          return promise
        end
      end

      # Return a promise for resolving a value from something like .count
      def resolve_promises
        @resolve_promises ||= []
      end


      def resolve_dep
        @resolve_dep ||= Dependency.new
      end

      def resolved_value
        if @value.respond_to?(:has_value?) && @model.has_value?
          @model.value
        else
          nil
        end
      end

      # Call a method on the model once the model is loaded.  Return a promise
      # that will resolve when the model is loaded
      def run_once_loaded
        promise = Promise.new

        if @model.loaded_state == :loaded
          promise.resolve(nil)
        else
          proc do |comp|
            if @model.loaded_state == :loaded
              promise.resolve(nil)

              comp.stop
            end
          end.watch!
        end

        promise
      end

      # Returns a promise that is resolved/rejected when the query is complete.  Any
      # passed block will be passed to the promises then.  Then will be passed the model.
      def fetch(&block)
        Volt.logger.warn('Deprication warning: in 0.9.3.pre4, all query methods on store now return Promises, so you can juse use .all or .first instead of .fetch')
        begin
          raise
        rescue => e
          puts e.inspect
          puts e.backtrace.join("\n")
        end
        promise = Promise.new

        # Run the block after resolve if a block is passed in
        promise = promise.then(&block) if block

        if @model.loaded_state == :loaded
          promise.resolve(@model)
        else
          proc do |comp|
            if @model.loaded_state == :loaded
              promise.resolve(@model)

              comp.stop
            end
          end.watch!
        end

        promise
      end

      # Called from backend when an item is added
      def add(index, data)
        $loading_models = true

        Model.no_validate do
          data_id = data['id'] || data[:id]

          # Don't add if the model is already in the ArrayModel (from the client already)
          unless @ids[data_id]
            @ids[data_id] = true
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

      # Called from the server when it removes an item.
      def remove(ids)
        $loading_models = true
        ids.each do |id|
          # TODO: optimize this delete so we don't need to loop
          @model.each_with_index do |model, index|
            if model.id == id
              @ids.delete(id)
              del = @model.delete_at(index)
              break
            end
          end
        end

        $loading_models = false
      end

      # Called when all models are removed
      def clear
        @ids = {}
      end

      def channel_name
        @model.path[-1]
      end

      # Called when the client adds an item.
      def added(model, index)
        if model.persistor
          # Track the the model got added
          @ids[model.id] = true
        end
      end

      # Called when the client removes an item
      def removed(model)
        remove_tracking_id(model)

        if defined?($loading_models) && $loading_models
          return
        else
          StoreTasks.delete(channel_name, model.attributes[:id])
        end
      end

      def remove_tracking_id(model)
        if model.persistor
          # Tell the persistor it was removed
          @ids.delete(model.id)
        end
      end

      def async?
        true
      end

      private
    end
  end
end
