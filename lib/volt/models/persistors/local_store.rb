require 'volt/models/persistors/base'
require 'volt/utils/local_storage'
require 'json'

module Persistors

  # Backs a collection in the local store
  class LocalStore < Base
    def initialize(model)
      @model = model
    end

    # Find the root for this model
    def root_model
      node = @model

      loop do
        parent = node.parent
        if parent
          node = parent
        else
          break
        end
      end

      return node
    end

    # Called when a model is added to the collection
    def added(model, index)
      root_model.persistor.save_all
    end

    def loaded
      # When the main model is first loaded, we pull in the data from the
      # store if it exists
      if @model.path == []
        json_data = LocalStorage['volt-store']
        if json_data
          root_attributes = JSON.parse(json_data)

          @loading_data = true
          root_attributes.each_pair do |key, value|
            @model.send(:"#{key}=", value)
          end
          @loading_data = nil
        end
      end
    end

    # Callled when an item is changed (or removed)
    def changed(attribute_name)
      root_model.persistor.save_all
    end

    # Called on the root
    def save_all
      return if @loading_data

      json_data = JSON.dump(@model.to_h)

      LocalStorage['volt-store'] = json_data
    end
  end
end