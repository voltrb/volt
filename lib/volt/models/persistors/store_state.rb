module Volt
  module Persistors
    # StoreState provides method for a store to track its loading state.
    module StoreState
      # Called when a collection loads
      def loaded(initial_state = nil)
        if initial_state
          @model.change_state_to(:loaded_state, initial_state)
        elsif !@loaded_state
          @model.change_state_to(:loaded_state, :not_loaded)
        end
      end
    end
  end
end
