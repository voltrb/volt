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

    # puts "Load data on #{collection.inspect} - #{query.inspect}"
    live_query.add_channel(@channel, Volt.user)

    errors = {}

    begin
      # Get the initial data
      initial_data = live_query.initial_data
    rescue => exception
      # Capture and pass up any exceptions
      error = { error: exception.message }
    end

    if initial_data[0]
      # Remove any attributes the user doesn't have permissions to see
      # TODO: locally, we should just reuse this model
      initial_data[0][1] = filter_attributes(collection, initial_data[0][1])
    end

    [initial_data, error]
  end

  # Loads up an instance of the class and runs the read permissions on it
  # and removes and denied or not allowed fields.
  def filter_attributes(path, data)
    # Load the model and check its permissions
    klass = Volt::Model.class_at_path([path])
    inst = klass.new(data, {}, :loaded)

    inst.filter_fields!

    return inst.attributes
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
