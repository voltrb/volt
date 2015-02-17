module Volt
  module StateHelpers
    def loaded_state
      state_for(:loaded_state)
    end

    def loaded?
      loaded_state == :loaded
    end
  end
end