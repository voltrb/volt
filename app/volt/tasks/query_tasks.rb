require_relative 'live_query/data_store'
require_relative 'live_query/live_query_pool'

class QueryTasks < Volt::TaskHandler
  @@live_query_pool = LiveQueryPool.new(DataStore.new)
  @@channel_live_queries = {}

  def self.live_query_pool
    @@live_query_pool
  end

  # The dispatcher passes its self in
  def initialize(channel, dispatcher = nil)
    @channel = channel
    @dispatcher = dispatcher
  end

  def add_listener(collection, query)
    live_query = @@live_query_pool.lookup(collection, query)
    track_channel_in_live_query(live_query)

    if @channel
      # For requests from the client (with @channel), we track the channel
      # so we can send the results back.  Server side requests don't stay live,
      # they simply return to :dirty once the query is issued.
      @channel.user_id = Volt.user_id

      live_query.add_channel(@channel)
    end

    errors = {}

    begin
      # Get the initial data
      initial_data = live_query.initial_data
    rescue => exception
      # Capture and pass up any exceptions
      error = { error: exception.message }
    end

    if initial_data
      # Only send the filtered attributes for this user
      initial_data.map! do |data|
        [data[0], live_query.model_for_filter(data[1]).filtered_attributes]
      end
    end

    # @@live_query_pool.print

    [initial_data, error]
  end

  def initial_data
    data = live_query.initial_data
    data[:_id] = data[:_id].to_s

    data
  end

  # Remove a listening channel, the LiveQuery will automatically remove
  # itsself from the pool when there are no channels.
  def remove_listener(collection, query)
    live_query = @@live_query_pool.lookup(collection, query)
    live_query.remove_channel(@channel)
    #
    # puts "REMOVE LIST1"
    # @@live_query_pool.print
  end

  # Removes a channel from all associated live queries
  def close!
    live_queries = @@channel_live_queries[@channel]

    if live_queries
      live_queries.each do |live_query|
        live_query.remove_channel(@channel)
      end
    end

    @@channel_live_queries.delete(@channel)
  end

  private

  # Tracks that this channel will be notified from the live query.
  def track_channel_in_live_query(live_query)
    @@channel_live_queries[@channel] ||= []
    @@channel_live_queries[@channel] << live_query
  end
end
