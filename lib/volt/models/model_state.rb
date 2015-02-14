module Volt
  # All models have a state that has to do with it being loaded, in process of
  # being loaded, or not yet loading.
  module ModelState
    def change_state_to(state_name, state)
      if @persistor && @persistor.respond_to?(:change_state_to)
        @persistor.change_state_to(state_name, state)
      else
        instance_variable_set(:"@#{state_name}", state)
      end
    end

    def state_for(state_name)
      if @persistor && @persistor.respond_to?(:state_for)
        @persistor.state_for(state_name)
      else
        instance_variable_get(:"@#{state_name}")
      end
    end

    def loaded_state
      state_for(:loaded_state)
    end

    def loaded?
      loaded_state == :loaded
    end
  end
end
