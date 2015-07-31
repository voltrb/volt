require_relative 'live_query'
require 'volt/utils/generic_pool'

# LiveQueryPool runs on the server and keeps track of all outstanding
# queries.

class LiveQueryPool < Volt::GenericPool
  attr_reader :volt_app

  def initialize(data_store, volt_app)
    @data_store = data_store
    @volt_app = volt_app
    super()
  end

  def lookup(collection, query)
    super(collection, query)
  end

  def updated_collection(collection, skip_channel, from_message_bus=false)
    puts "UPDATE COLLECTION: #{collection.inspect} - #{skip_channel.inspect} - #{from_message_bus.inspect}"
    # collection = collection.to_sym
    lookup_all(collection).each do |live_query|
      live_query.update(skip_channel)
    end

    msg_bus = @volt_app.message_bus
    if !from_message_bus && collection != 'active_volt_instances' && msg_bus
      msg_bus.publish('volt_collection_update', collection)
    end
  end

  # Show a live updating list of the current live queries
  if RUBY_PLATFORM == 'opal'
    def live_log
      Thread.new do
        loop do
          puts "------ live queries ------"
          @pool.each do |live_query|
            puts live_query.inspect
          end

          sleep 2
        end
      end
    end
  end

  private

  # Creates the live query if it doesn't exist, and stores it so it
  # can be found later.
  def create(collection, query = {})
    # collection = collection.to_sym
    # If not already setup, create a new one for this collection/query
    LiveQuery.new(@volt_app, self, @data_store, collection, query)
  end
end
