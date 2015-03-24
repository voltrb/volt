module Volt
  module Persistors
    # Implements the base persistor functionality.
    class Base
      def loaded(initial_state = nil)
      end

      def changed(attribute_name)
      end

      def added(model, index)
      end

      # For removed, the default action is to call changed for it
      def removed(attribute_name)
        changed(attribute_name)
      end

      def event_added(event, first, first_for_event)
      end

      def event_removed(event, last, last_for_event)
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
