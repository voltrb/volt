module Persistors
  # Implements the base persistor functionality.
  class Base
    def loaded
    end
    
    # For deleted, the default action is to call changed for it
    def deleted(attribute_name)
      changed(attribute_name)
    end
    
    def changed(attribute_name)
    end
    
    def added(model)
    end
    
    def event_added(event, scope_provider, first)
    end
    
    def event_removed(event, no_more_events)
    end
  end
end