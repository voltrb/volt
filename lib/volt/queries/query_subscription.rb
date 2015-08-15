# The QuerySubscription keeps track of a LiveQuerry and a Channel which should be
# updated when the LiveQuery changes.

module Volt
  class QuerySubscription
    def initialize(live_query, channel)
      @live_query = live_query
      @channel = channel

      if @channel
        chan_subs = @live_query.volt_app.channel_query_subscriptions
        chan_subs[@channel] ||= {}
        chan_subs[@channel][self] = true
      end

      @old_data = []
    end

    def remove
      # Remove from channel
      if @channel
        chan_subs = @live_query.volt_app.channel_query_subscriptions
        subs_for_chan = chan_subs[@channel]
        subs_for_chan.delete(self) if subs_for_chan
      end

      # Remove from the pool
      @live_query.remove_query_subscription(@channel)
    end

    def initial_data
      # puts "INITIAL DATA: #{@live_query.last_data.inspect}"
      begin
        filter_data(@live_query.last_data)
      rescue => e
        puts e.inspect
        puts e.backtrace.join("\n")
      end
    end

    def notify_updated(diff)
      puts "UPD: #{@live_query.collection.inspect}, #{@live_query.query.inspect}, #{diff.inspect}"
      @channel.send_message('updated', nil, @live_query.collection, @live_query.query, diff)
    end

    # Filters data based on the user's permissions
    def filter_data(data)
      data.map do |data|
        model = model_for_filter(data)

        # @channel might be nil
        Volt.as_user(@channel.try(:user_id)) do
          model.filtered_attributes.sync
        end
      end
    end

    # Takes in data to be sent to the client and sets up a model to test
    # field permissions against
    def model_for_filter(data)
      klass = Volt::Model.class_at_path([@live_query.collection])
      model = nil

      # Skip read validations when loading the model, no need to check read when checking
      # permissions.
      # TODO: We should probably document the possibility of data leak here, though really you
      # shouldn't be storing anything inside of the permissions block.
      Volt::Model.no_validate do
        model = klass.new(data, {}, :loaded)
      end

      model
    end
  end
end