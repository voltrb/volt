module Persistors
  # Implements the base persistor functionality.
  class Base
    def loaded
    end

    def changed(attribute_name)
    end

    def added(model, index)
    end

    # For removed, the default action is to call changed for it
    def removed(attribute_name)
      changed(attribute_name)
    end

    def event_added(event, scope_provider, first, first_for_event)
    end

    def event_removed(event, no_more_events)
    end
  end
end
