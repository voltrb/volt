require_relative 'live_query'
require 'volt/utils/generic_pool'

# LiveQueryPool runs on the server and keeps track of all outstanding
# queries.

class LiveQueryPool < Volt::GenericPool
  def initialize(data_store, volt_app)
    @data_store = data_store
    @volt_app = volt_app
    super()
  end

  def lookup(collection, query)
    # collection = collection.to_sym
    query = normalize_query(query)

    super(collection, query)
  end

  def updated_collection(collection, skip_channel, from_message_bus=false)
    # collection = collection.to_sym
    lookup_all(collection).each do |live_query|
      live_query.run(skip_channel)
    end

    msg_bus = @volt_app.message_bus
    if !from_message_bus && collection != 'active_volt_instances' && msg_bus
      msg_bus.publish('volt_collection_update', collection)
    end
  end

  private

  # Creates the live query if it doesn't exist, and stores it so it
  # can be found later.
  def create(collection, query = {})
    # collection = collection.to_sym
    # If not already setup, create a new one for this collection/query
    LiveQuery.new(self, @data_store, collection, query)
  end

  def normalize_query(query)
    # TODO: add something to sort query properties so the queries are
    # always compared the same.
    query
  end
end
