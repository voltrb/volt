require 'volt/models/persistors/base'

module Volt
  module Persistors
    class Flash < Base
      def initialize(model)
        @model = model
      end

      def added(model, index)
        if Volt.client?
          # Setup a new timer for clearing the flash.
          `
            setTimeout(function() {
              self.$clear_model(model);
            }, 5000);
          `
        end
      end

      def clear_model(model)
        @model.delete(model)

        # Clear out the parent collection (usually the main flash)
        # Makes it so flash.empty? reflects if there is any outstanding
        # flashes.
        if @model.size == 0
          collection_name = @model.path[-1]
          @model.parent.delete(collection_name)
        end
      end
    end
  end
end
