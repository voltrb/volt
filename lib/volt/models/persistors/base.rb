module Persistors
  # Implements the base persistor functionality.
  class Base
    # For deleted, the default action is to call changed for it
    def deleted(attribute_name)
      changed(attribute_name)
    end
    
    def changed(attribute_name)
    end
    
    def added
    end
  end
end