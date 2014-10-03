require 'volt/models/persistors/store'
require 'volt/models/persistors/store_state'

module Persistors
  class ModelStore < Store
    include StoreState

    ID_CHARS = [('a'..'f'), ('0'..'9')].map {|v| v.to_a }.flatten

    attr_reader :model
    attr_accessor :in_identity_map

    def initialize(model, tasks)
      super

      @in_identity_map = false
    end

    def add_to_collection
      @in_collection = true
      ensure_setup
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

      return id.join
    end

    # Called when the model changes
    def changed(attribute_name=nil)
      path = @model.path

      promise = Promise.new

      ensure_setup

      path_size = path.size
      if !(defined?($loading_models) && $loading_models) && @tasks && path_size > 0 && !@model.nil?
        if path_size > 3 && (parent = @model.parent) && source = parent.parent
          @model.attributes[:"#{path[-4].singularize}_id"] = source._id
        end

        if !collection
          puts "Attempting to save model directly on store."
          raise "Attempting to save model directly on store."
        else
          @tasks.call('StoreTasks', 'save', collection, self_attributes) do |errors|
            if errors.size == 0
              promise.resolve
            else
              promise.reject(errors)
            end
          end
        end
      end

      return promise
    end

    def event_added(event, first, first_for_event)
      if first_for_event && event == :changed
        ensure_setup
      end
    end

    # Update the models based on the id/identity map.  Usually these requests
    # will come from the backend.
    def self.changed(model_id, data)
      model = @@identity_map.lookup(model_id)

      if model
        data.each_pair do |key, value|
          if key != '_id'
            model.send(:"#{key}=", value)
          end
        end
      end
    end

    def [](val)
      raise "Models do not support hash style lookup.  Hashes inserted into other models are converted to models, see https://github.com/voltrb/volt#automatic-model-conversion"
    end

    private
      # Return the attributes that are only for this store, not any sub-associations.
      def self_attributes
        # Don't store any sub-stores, those will do their own saving.
        @model.attributes.reject {|k,v| v.is_a?(Model) || v.is_a?(ArrayModel) }
      end

      def collection
        @model.path[-2]
      end

  end
end
