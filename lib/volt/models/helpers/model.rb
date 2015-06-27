module Volt
  module Models
    module Helpers
      module Model
        def saved_state
          state_for(:saved_state) || :saved
        end

        def saved?
          saved_state == :saved
        end
      end
    end
  end
end
