module Volt
  module Persistors
    # StoreState provides method for a store to track its loading state.
    module StoreState
      # Called when a collection loads
      def loaded(initial_state = nil)
        change_state_to(:state, initial_state || :not_loaded)
      end

      def state
        state_for(:state)
      end

      def state_for(state_name)
        ivar_name = :"@#{state_name}"

        # Depend on the dep
        state_dep_for(state_name).depend

        # Also depend on root for tracking
        @root_dep.depend

        instance_variable_get(ivar_name)
      end

      # Called from the QueryListener when the data is loaded
      def change_state_to(state_name, new_state)
        # use an instance variable for the state storage
        ivar_name = :"@#{state_name}"

        old_state = instance_variable_get(ivar_name)
        instance_variable_set(ivar_name, new_state)

        # Trigger changed on the 'state' method
        if old_state != @state
          dep = state_dep_for(state_name, false)
          dep.changed! if dep
        end
      end

      private
      # Get a state ivar for state_name
      # @params [String] the name of the state variable
      # @params [Boolean] if true, one will be created if it does not exist
      def state_dep_for(state_name, create=true)
        dep_ivar_name = :"@#{state_name}_dep"
        dep = instance_variable_get(dep_ivar_name)
        if !dep && create
          dep = Dependency.new
          instance_variable_set(dep_ivar_name, dep)
        end

        dep
      end
    end
  end
end
