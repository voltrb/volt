# Tracks a channel and a query on a collection.  Alerts
# the listener when the data in the query changes.
class LiveQuery
  attr_reader :volt_app, :pool, :collection, :query, :last_data

  def initialize(volt_app, pool, data_store, collection, query)
    @volt_app = volt_app
    @pool = pool
    @collection = collection
    @query = query

    @query_subscriptions = {}
    @data_store = data_store

    # initial run
    run
  end

  # Decrements the count on the LiveQueryPool.  This is called when a
  # QuerySubscrption no longer is using this LiveQuery.
  def remove_reference
    @pool.remove(@collection, @query)
  end

  def query_subscription_for_channel(channel)
    @query_subscriptions[channel] ||= begin
      QuerySubscription.new(self, channel)
    end
  end

  def remove_query_subscription(channel)
    @query_subscriptions.delete(channel)

    if @query_subscriptions.empty?
      # No more query_subscriptions, this means no one is using this query,
      # remove it from the pool
      puts "REMOVE FROM POOL: #{@collection} - #{@query.inspect}"

      # Reduce the count on the live query
      begin
        remove_reference
      rescue Volt::GenericPoolDeleteException => e
        # ignore
        Volt.logger.error e.inspect
      end
    end
  end

  # Skip channel is the channel of the user who made the change
  def run(skip_channel = nil)
    @last_data = @data_store.query(@collection, @query)
  end

  def update(skip_channel=nil)
    puts "UPDATE: #{@query.inspect}"
    new_data = run

    notify_updated(skip_channel)

    @last_data = new_data
  end

  def notify_updated(skip_channel)
    notify!(skip_channel) do |query_subscription|
      query_subscription.notify_updated(@last_data)
    end
  end

  # Runs through each query subscription, yielding all except the optional
  # one with skip_channel.

  def notify!(skip_channel = nil)
    query_subs = @query_subscriptions
    if skip_channel
      query_subs = query_subs.reject { |channel, query_sub| channel == skip_channel }
    end

    query_subs.values.each do |query_sub|
      yield(query_sub)
    end
  end


  def inspect
    "<#{self.class} #{@collection}: #{@query.inspect}>"
  end
end
