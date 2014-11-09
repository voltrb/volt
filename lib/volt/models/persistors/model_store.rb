require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'

if RUBY_PLATFORM == 'opal'
else
  require 'mongo'
end

module Volt
  module Persistors
    class ModelStore < Store
      include StoreState

      ID_CHARS = [('a'..'f'), ('0'..'9')].map(&:to_a).flatten

      attr_reader :model
      attr_accessor :in_identity_map

      def initialize(model, tasks)
        super

        @in_identity_map = false
      end

      def add_to_collection
        @in_collection = true
        ensure_setup

        # Call changed, return the promise
        changed
      end

      def remove_from_collection
        @in_collection = false
      end

      # Called the first time a value is assigned into this model
      def ensure_setup
        if @model.attributes
          @model.attributes[:_id] ||= generate_id

          add_to_identity_map
        end
      end

      def add_to_identity_map
        unless @in_identity_map
          @@identity_map.add(@model._id, @model)

          @in_identity_map = true
        end
      end

      # Create a random unique id that can be used as the mongo id as well
      def generate_id
        id = []
        24.times { id << ID_CHARS.sample }

        id.join
      end

      def save_changes?
        if RUBY_PLATFORM == 'opal'
          return !(defined?($loading_models) && $loading_models) && @tasks
        else
          return true
        end
      end

      # Called when the model changes
      def changed(attribute_name = nil)
        path = @model.path

        promise = Promise.new

        ensure_setup

        path_size = path.size
        if save_changes? && path_size > 0 && !@model.nil?
          if path_size > 3 && (parent = @model.parent) && (source = parent.parent)
            @model.attributes[:"#{path[-4].singularize}_id"] = source._id
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

        StoreTasks.save(collection, @model.path, self_attributes).then do
          save_promises = @save_promises
          @save_promises = nil
          save_promises.each {|promise|  promise.resolve(nil) }
        end.fail do |errors|
          save_promises = @save_promises
          @save_promises = nil
          save_promises.each {|promise|  promise.reject(errors) }
        end

      end

      def event_added(event, first, first_for_event)
        if first_for_event && event == :changed
          ensure_setup
        end
      end

      # Update the models based on the id/identity map.  Usually these requests
      # will come from the backend.
      def self.changed(model_id, data)
        Model.nosave do
          model = @@identity_map.lookup(model_id)

          if model
            data.each_pair do |key, value|
              if key != :_id
                model.send(:"_#{key}=", value)
              end
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
        # Don't store any sub-stores, those will do their own saving.
        @model.attributes.reject { |k, v| v.is_a?(Model) || v.is_a?(ArrayModel) }
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

          # Passed, save it
          id = values[:_id]

          # Try to create
          # TODO: Seems mongo is dumb and doesn't let you upsert with custom id's
          begin
            # values['_id'] = BSON::ObjectId('_id') if values['_id']
            db[collection].insert(values)
          rescue Mongo::OperationFailure => error
            # Really mongo client?
            if error.message[/^11000[:]/]
              # Update because the id already exists
              update_values = values.dup
              update_values.delete(:_id)
              db[collection].update({ _id: id }, update_values)
            else
              return { error: error.message }
            end
          end

          # puts "Update Collection: #{collection.inspect} - #{values.inspect} -- #{Thread.current['in_channel'].inspect}"
          QueryTasks.live_query_pool.updated_collection(collection.to_s, Thread.current['in_channel'])
          return {}
        end
      end
    end
  end
end
