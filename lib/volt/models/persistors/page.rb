require 'volt/models/persistors/base'

module Volt
  module Persistors
    class Page < Base
      def auto_generate_id
        true
      end

      def where(query)
        @model.select do |model|
          # Run through each key in the query and make sure the value matches.
          # We use .all? because once one fails to match, we can return false,
          # because it wouldn't match as a whole.
          query.all? do |key, value|
            model.get(key) == value
          end
        end
      end
    end
  end
end
