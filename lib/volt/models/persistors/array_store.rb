require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'
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
        @limit = @model.options[:limit]
        @skip = @model.options[:skip]

        @skip = nil if @skip == 0
      end

      def inspect
        "<#{self.class.to_s}:#{object_id} #{@query}, #{@skip}, #{@limit}>"
      end

      # Called when an each binding is listening
      def event_added(event, first, first_for_event)
        # First event, we load the data.
        if first
          # puts "Event added"
          @listener_event_counter.add
        end
      end

      # Called when an each binding stops listening
      def event_removed(event, last, last_for_event)
        # Remove listener where there are no more events on this model
        if last
          # puts "event removed"
          @listener_event_counter.remove
        end
      end

      # Called by child models to track their listeners
      def listener_added
        # puts "LIST ADD: #{object_id}"
        @listener_event_counter.add
      end

      # Called by child models to track their listeners
      def listener_removed
        # puts "LIST REMO #{object_id}"
        @listener_event_counter.remove
      end

      # Called when an event is removed and we no longer want to keep in
      # sync with the database.  The data is kept in memory and the model's
      # loaded_state is marked as "dirty" meaning it may not be in sync.
      def stop_listening
        Timers.next_tick do
          Computation.run_without_tracking do
            if @listener_event_counter.count == 0
              if @query_listener
                # puts "Stop Query"
                @query_listener.remove_store(self)
                @query_listener = nil
              end

              @model.change_state_to(:loaded_state, :dirty)
            end
          end
        end
      end

      # Called the first time data is requested from this collection
      def load_data
        Computation.run_without_tracking do
          loaded_state = @model.loaded_state

          # puts "LOAD DATA: #{loaded_state}"
          # Don't load data from any queried
          if loaded_state == :not_loaded || loaded_state == :dirty
            # puts "LOAD DATA"
            # puts "Load Data at #{@model.path.inspect} - query: #{@query.inspect} on #{self.inspect}"
            @model.change_state_to(:loaded_state, :loading)

            run_query(@model, @query, @skip, @limit)
          end
        end
      end

      def run_query(model, query = {}, skip = nil, limit = nil)
        @model.clear
        # puts "RUN QUERY: #{query.inspect}"

        collection = model.path.last
        # Scope to the parent
        if model.path.size > 1
          parent = model.parent

          parent.persistor.ensure_setup if parent.persistor

          if parent && (attrs = parent.attributes) && attrs[:_id].true?
            query[:"#{model.path[-3].singularize}_id"] = attrs[:_id]
          end
        end

        # The full query contains the skip and limit
        full_query = [query, skip, limit]
        # puts "RUN QUERY: #{model.path.inspect} - #{full_query.inspect}, #{self.object_id}"
        @query_listener = @@query_pool.lookup(collection, full_query) do
          # Create if it does not exist
          QueryListener.new(@@query_pool, @tasks, collection, full_query)
        end

        # puts "ADD STORE: #{self.model.inspect}"
        @query_listener.add_store(self)
      end

      # Find can take either a query object, or a block that returns a query object.  Use
      # the block style if you need reactive updating queries
      def find(query = nil, &block)
        # Set a default query if there is no block
        if block
          if query
            fail 'Query should not be passed in to a find if a block is specified'
          end
          query = block
        else
          query ||= {}
        end

        Cursor.new([], @model.options.merge(query: query))
      end

      def limit(limit)
        Cursor.new([], @model.options.merge(limit: limit))
      end

      def skip(skip)
        Cursor.new([], @model.options.merge(skip: skip))
      end

      # Returns a promise that is resolved/rejected when the query is complete.  Any
      # passed block will be passed to the promises then.  Then will be passed the model.
      def then(&block)
        fail 'then must pass a block' unless block
        promise = Promise.new

        promise = promise.then(&block)

        if @model.loaded_state == :loaded
          promise.resolve(@model)
        else
          Proc.new do |comp|
            if @model.loaded_state == :loaded
              promise.resolve(@model)

              comp.stop
            else
              puts "STATE: #{@model.loaded_state}"
            end

          end.watch!

          # -> { loaded }.watch_until!(:loaded) do
            # Run when the state is changed to :loaded
            # promise.resolve(@model)
          # end
        end

        promise
      end

      # Called from backend
      def add(index, data)
        # puts "ADD1: #{index} - #{data.inspect} - #{object_id}"
        $loading_models = true

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
