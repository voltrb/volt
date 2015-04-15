module Volt
  module Query
    # Normalizes queries so queries that are the same have the same order and parts
    class Normalizer
      def self.normalize(query)
        query = merge_finds_and_move_to_front(query)

        query = reject_skip_zero(query)

        query
      end

      def self.merge_finds_and_move_to_front(query)
        # Map first parts to string
        query = query.map {|v| v[0] = v[0].to_s ; v }
        has_find = query.find {|v| v[0] == 'find' }

        if has_find
          # merge any finds
          merged_find_query = {}
          query = query.reject do |query_part|
            if query_part[0] == 'find'
              # on a find, merge into finds
              find_query = query_part[1]
              merged_find_query.merge!(find_query) if find_query

              # reject
              true
            else
              false
            end
          end

          # Add finds to the front
          query.insert(0, ['find', merged_find_query])
        else
          # No find was done, add it in the first position
          query.insert(0, ['find'])
        end

        query
      end

      def self.reject_skip_zero(query)
        query.reject do |query_part|
          query_part[0] == 'skip' && query_part[1] == 0
        end
      end
    end
  end
end