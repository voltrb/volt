module Volt
  module Persistors
    # Implements the base persistor functionality.
    class Base
      def initialize(model)
        @model = model
      end

      def loaded(initial_state = nil)
        @model.change_state_to(:loaded_state, initial_state || :loaded)
      end

      # Method that is called when data on the model changes.
      # @returns [true|Promise] - should return a Promise or true.  On async
      #    persistors, the promise from set and save! will wait on the
      #    Promise.
      def changed(attribute_name)
      end

      def added(model, index)
      end

      # For removed, the default action is to call changed for it
      def removed(attribute_name)
        changed(attribute_name)
      end

      # Called when the model is cleared (all child models removed)
      def clear
      end

      def event_added(event, first, first_for_event)
      end

      def event_removed(event, last, last_for_event)
      end

      # Specify if this collection should auto-generate id's
      def auto_generate_id
        false
      end

      # return true if this persistor is asynchronus and needs to return
      # Promises.
      def async?
        false
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

        node
      end
    end
  end
end
