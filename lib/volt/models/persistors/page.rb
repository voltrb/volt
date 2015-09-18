require 'volt/models/persistors/base'

module Volt
  module Persistors
    class Page < Base
      def auto_generate_id
        true
      end

      def where(query)
        @model.select do |model|
          # Filter through each part of the query and make sure it matches.
          has_values = []
          query.each_pair do |key, value|
            has_values << (model.get(key) == value)
          end

          has_values.all?
        end
      end
    end
  end
end
