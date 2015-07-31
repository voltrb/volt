# QueryTasks is responsible for passing back the data from a query.  It will
# be run both from the client side and server side.  From the client it passed
# data with websockets.  From the server it uses the stub channel to pass data
# directly.

class QueryTasks < Volt::Task
  def add_listener(collection, query)
    if @channel
      # For requests from the client (with @channel), we track the channel
      # so we can send the results back.  Server side requests don't stay live,
      # they simply return to :dirty once the query is issued.
      @channel.user_id = Volt.current_user_id
    end

    query_subscription = subscription(collection, query)

    errors = {}

    begin
      # Get the initial data
      initial_data = query_subscription.initial_data
    rescue => exception
      # Capture and pass up any exceptions
      error = { error: exception.message }
    end

    [initial_data, error]
  end

  def initial_data
    live_query.initial_data(@channel)
  end

  # Remove a listening channel, the LiveQuery will automatically remove
  # itsself from the pool when there are no channels.
  def remove_listener(collection, query)
    # TODO: Need LiveQueryPool to be counting, and we need to remove it
    query_sub = subscription(collection, query)
    query_sub.remove
  end

  # Remove all QuerySubscriptions for a channel
  def close!
    query_subscriptions = @volt_app.channel_query_subscriptions[@channel]

    if query_subscriptions
      query_subscriptions.keys.reverse.each(&:remove)
    end
  end

  private

  def subscription(collection, query)
    # Lookup or create the live query
    live_query = @volt_app.live_query_pool.lookup(collection, query)

    # Find or create a QuerySubscription for this channel
    live_query.query_subscription_for_channel(@channel)
  end

end
