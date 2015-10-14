# Tracks a channel and a query on a collection.  Alerts
# the listener when the data in the query changes.
#
# has_many QuerySubscriptions

require 'volt/queries/query_diff'
require 'volt/queries/query_runner'

module Volt
  class LiveQuery
    attr_reader :volt_app, :pool, :collection, :query, :last_data

    def initialize(volt_app, pool, data_store, collection, query)
      @volt_app = volt_app
      @pool = pool
      @collection = collection
      @query = query

      @query_runner = QueryRunner.new(data_store, collection, query)
      # Grab the associations from the query runner
      @associations = @query_runner.associations

      @query_subscriptions = {}
      @data_store = data_store

      # initial run
      @last_data = run
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

        # Reduce the count on the live query
        begin
          remove_reference
        rescue Volt::GenericPoolDeleteException => e
          # ignore
          Volt.logger.error e.inspect
        end
      end
    end

    def run
      @query_runner.run
    end


    def update(skip_channel=nil)
      new_data = run

      if new_data.is_a?(Array)
        # Diff the new data
        diff = QueryDiff.new(@last_data, @associations).run(new_data)

        notify_updated(skip_channel, diff)
      else
        # When working with queries that return a value, we don't diff, we just
        # push an update operation
        notify_updated(skip_channel, {'u' => new_data})
      end

      @last_data = new_data
    end

    def notify_updated(skip_channel, diff)
      # TODO: We should be able to mostly skip our own channel
      # notify!(skip_channel) do |query_subscription|
      notify! do |query_subscription|
        query_subscription.notify_updated(diff)
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
end
