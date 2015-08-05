require 'volt/queries/query_subscription'
require 'volt/utils/generic_pool'

# QuerySubscriptionPool keeps track of QuerySubscriptions
module Volt
  class QuerySubscriptionPool
    def initialize(volt_app)
      @pool = {}
      @volt_app = volt_app
    end

    def lookup(*args)
      @pool[[*args]] ||= begin
        create(*args)
      end
    end

    def remove(*args)
      @pool.delete([*args])
    end

    def clear
      @pool.values.each(&:remove)
      @pool = {}
    end

    private

    # Creates the live query if it doesn't exist, and stores it so it
    # can be found later.
    def create(collection, query, channel)
      # collection = collection.to_sym
      # If not already setup, create a new one for this collection/query
      QuerySubscription.new(@volt_app, self, collection, query, channel)
    end
  end
end