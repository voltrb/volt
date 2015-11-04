require 'volt/models/persistors/base'
require 'volt/utils/html_storage'
require 'volt/utils/ejson'

module Volt
  module Persistors
    # Backs a collection in the local store
    class HtmlStore < Base

      # Implement in LocalStore and SessionStore
      def self.storage
        raise 'should be implemented in SessionStore or LocalStore'
      end

      # Called when a model is added to the collection
      def added(model, index)
        root_model.persistor.save_all
      end

      def loaded(initial_state = nil)
        super
        # When the main model is first loaded, we pull in the data from the
        # store if it exists
        if @model.path == []
          json_data = self.class.storage['volt-store']
          if json_data
            root_attributes = EJSON.parse(json_data)

            @loading_data = true
            root_attributes.each_pair do |key, value|
              @model.send(:"_#{key}=", value)
            end
            @loading_data = nil
          end
        end
      end

      # Called when an item is changed (or removed)
      def changed(attribute_name)
        root_model.persistor.save_all

        true
      end

      # Called on the root
      def save_all
        return if @loading_data

        json_data = EJSON.stringify(@model.to_h)

        self.class.storage['volt-store'] = json_data
      end
    end
  end
end
