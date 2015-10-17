require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'

module Volt
  module Persistors
    class ModelStore < Store
      include StoreState

      attr_reader :model
      attr_accessor :in_identity_map

      def initialize(model, tasks)
        super

        @in_identity_map = false
      end

      def loaded(initial_state = nil)
        initial_state = :loaded if model.path == []

        model.change_state_to(:loaded_state, initial_state)
      end

      def auto_generate_id
        true
      end

      # Called the first time a value is assigned into this model
      def ensure_setup
        add_to_identity_map
      end

      def add_to_identity_map
        unless @in_identity_map
          @@identity_map.add(@model.id, @model)

          @in_identity_map = true
        end
      end

      def save_changes?
        if RUBY_PLATFORM == 'opal'
          !(defined?($loading_models) && $loading_models) && @tasks
        else
          true
        end
      end

      # Called when the model changes
      def changed(attribute_name = nil)
        path = @model.path

        promise = Promise.new

        ensure_setup

        path_size = path.size
        if save_changes? && path_size > 0 && !@model.nil?
          if path_size > 3 && (parent = @model.parent)
            # If we have a collection, go up one more.
            parent = parent.parent unless parent.is_a?(Volt::Model)
            @model.attributes[:"#{path[-4].singularize}_id"] = parent.id
          end

          if !collection
            puts 'Attempting to save model directly on store.'
            fail 'Attempting to save model directly on store.'
          else
            if RUBY_PLATFORM == 'opal'
              @save_promises ||= []
              @save_promises << promise

              queue_client_save
            else
              errors = save_to_db!(self_attributes)
              if errors.size == 0
                promise.resolve(nil)
              else
                promise.reject(errors)
              end
            end
          end
        end

        promise
      end

      def queue_client_save
        `
        if (!self.saveTimer) {
          self.saveTimer = setImmediate(self.$run_save.bind(self));
        }
        `
      end

      # Run save is called on the client side after a queued setImmediate.  It does the
      # saving on the front-end.  Adding a setImmediate allows multiple changes to be
      # batched together.
      def run_save
        # Clear the save timer
        `
        clearImmediate(self.saveTimer);
        delete self.saveTimer;
        `

        @model.change_state_to(:saved_state, :saving)

        StoreTasks.save(collection, @model.path, self_attributes).then do
          save_promises = @save_promises
          @save_promises = nil
          save_promises.each { |promise|  promise.resolve(nil) }

          @model.change_state_to(:saved_state, :saved)
        end.fail do |errors|
          save_promises = @save_promises
          @save_promises = nil

          # Rewrap in Volt::Errors
          errors = Volt::Errors.new(errors)
          save_promises.each { |promise| promise.reject(errors) }

          # Mark that we failed to save
          @model.change_state_to(:saved_state, :save_failed)
        end
      end

      def event_added(event, first, first_for_event)
        ensure_setup if first_for_event && event == :changed
      end

      # Update the models based on the id/identity map.  Usually these requests
      # will come from the backend.
      def self.changed(model_id, data)
        Model.no_save do
          model = @@identity_map.lookup(model_id)

          if model
            data.each_pair do |key, value|
              model.set(key, value)# if key != :id
            end
          end
        end
      end

      def [](val)
        fail 'Models do not support hash style lookup.  Hashes inserted into other models are converted to models, see https://github.com/voltrb/volt#automatic-model-conversion'
      end

      private

      # Return the attributes that are only for this store, not any sub-associations.
      def self_attributes
        @model.self_attributes
      end

      def collection
        @model.path[-2]
      end

      if RUBY_PLATFORM != 'opal'
        def db
          @@db ||= Volt::DataStore.fetch
        end

        # Do the actual writing of data to the database, only runs on the backend.
        def save_to_db!(values)
          # Check to make sure the model has no validation errors.
          errors = @model.errors
          return errors if errors.present?

          # Try to create
          update_result = db.update(collection, values)

          # An error hash will be returned if the update doesn't work
          return update_result if update_result

          # If we are running in a task, or the console, push update
          if (volt_app = Volt.current_app)
            volt_app.live_query_pool.updated_collection(collection.to_s, Thread.current['in_channel'])
          end
          {}
        end
      end
    end
  end
end
