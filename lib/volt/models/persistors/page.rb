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
          query.each_pair do |key, value|
            next false unless model.get(key) == value
          end

          true
        end
      end
    end
  end
end
