module Volt
  module Persistors
    class StoreFactory
      def initialize(tasks)
        @tasks = tasks
      end

      def new(model)
        if model.is_a?(ArrayModel)
          ArrayStore.new(model, @tasks)
        else
          ModelStore.new(model, @tasks)
        end
      end
    end
  end
end
