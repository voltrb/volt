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

        def collection_name
          path.last
        end
      end
    end
  end
end
