# The query tracker runs queries on the server and then sends update diffs
# as the queries change to the LiveQuery, which then passes them to the client
# or server's QueryListener.
require 'hashdiff'

# class QueryTracker
#   attr_accessor :results

#   def initialize(live_query, data_store)
#     @live_query = live_query
#     @data_store = data_store
#   end

#   # Runs the query, stores the results and updates the current_ids
#   def run(skip_channel = nil, initial_run = false)
#     puts "RUN: #{@live_query.inspect}"
#     # Run the query again
#     new_results = @data_store.query(@live_query.collection, @live_query.query)

#     unless initial_run
#       @live_query.notify_updated(skip_channel, new_results)
#     end

#     new_results
#   end
# end
