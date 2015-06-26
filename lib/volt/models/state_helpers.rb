module Volt
  module StateHelpers
    def loaded_state
      state_for(:loaded_state)
    end

    def loaded?
      loaded_state == :loaded
    end

    def saved_state
      state_for(:saved_state)
    end

    def saved?
      saved_state == :saved
    end
  end
end
