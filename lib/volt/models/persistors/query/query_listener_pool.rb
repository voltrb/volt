require 'volt/utils/generic_pool'
require 'volt/models/persistors/query/query_listener'

module Volt
  # Keeps track of all query listeners, so they can be reused in different
  # places.  Dynamically generated queries may end up producing the same
  # query in different places.  This makes it so we only need to track a
  # single query at once.  Data updates will only be sent once as well.
  class QueryListenerPool < GenericPool
    def print
      puts '--- Running Queries ---'

      @pool.each_pair do |table, query_hash|
        query_hash.each_key do |query|
          puts "#{table}: #{query.inspect}"
        end
      end
    end
  end
end
