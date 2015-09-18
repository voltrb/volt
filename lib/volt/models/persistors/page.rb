require 'volt/models/persistors/base'

module Volt
  module Persistors
    class Page < Base
      def auto_generate_id
        true
      end

      def where(query)
        result = @model.select do |model|
          # Run through each key in the query and make sure the value matches.
          # We use .all? because once one fails to match, we can return false,
          # because it wouldn't match as a whole.
          query.all? do |key, value|
            model.get(key) == value
          end
        end

        options = @model.options.merge(parent: @model, path: @model.path)
        @model.new_array_model(result, options)
      end
    end
  end
end
