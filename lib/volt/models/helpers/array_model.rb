module Volt
  module Models
    module Helpers
      module ArrayModel
        def loaded_state
          state_for(:loaded_state)
        end

        def loaded?
          loaded_state == :loaded
        end
      end
    end
  end
end
