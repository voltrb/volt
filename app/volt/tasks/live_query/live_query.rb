require_relative 'query_tracker'

# Tracks a channel and a query on a collection.  Alerts
# the listener when the data in the query changes.
class LiveQuery
  attr_reader :current_ids, :collection, :query

  def initialize(pool, data_store, collection, query)
    @pool = pool
    @collection = collection
    @query = query

    @channels = []
    @data_store = data_store

    @query_tracker = QueryTracker.new(self, @data_store)

    run
  end

  def run(skip_channel = nil)
    @query_tracker.run(skip_channel)
  end

  def notify_removed(ids, skip_channel)
    # puts "Removed: #{ids.inspect}"
    notify! do |channel|
      channel.send_message('removed', nil, @collection, @query, ids)
    end
  end

  def notify_added(index, data, skip_channel)
    # Make model for testing permissions against
    model = nil

    notify! do |channel|
      # Only load the model for filtering if we are sending to a channel
      # (skip if we are the only one listening)
      model ||= model_for_filter(data)

      filtered_data = nil
      Volt.as_user(channel.user_id) do
        filtered_data = model.filtered_attributes.sync
      end

      channel.send_message('added', nil, @collection, @query, index, filtered_data)
    end
  end

  def notify_moved(id, new_position, skip_channel)
    # puts "Moved: #{id}, #{new_position}"
    notify! do |channel|
      channel.send_message('moved', nil, @collection, @query, id, new_position)
    end
  end

  def notify_changed(id, data, skip_channel)
    model = nil

    notify!(skip_channel) do |channel|
      # Only load the model for filtering if we are sending to a channel
      # (skip if we are the only one listening)
      model ||= model_for_filter(data)

      filtered_data = nil
      Volt.as_user(channel.user_id) do
        filtered_data = model.filtered_attributes.sync
      end
      # puts "Changed: #{id}, #{data} to #{channel.inspect}"
      channel.send_message('changed', nil, @collection, @query, id, filtered_data)
    end
  end

  # return the query results the first time a channel connects
  def initial_data
    @query_tracker.results.map.with_index do |data, index|
      data = data.dup

      [index, data]
    end
  end

  # Lookup the model class
  def model_class
    # recreate the "path" from the collection
    Volt::Model.class_at_path([collection, :[]])
  end

  def add_channel(channel)
    @channels << channel
  end

  def remove_channel(channel)
    deleted = @channels.delete(channel)

    # remove this query, no one is listening anymore
    if @channels.empty?
      begin
        @pool.remove(@collection, @query)
      rescue Volt::GenericPoolDeleteException => e
        # ignore
      end
    end
  end

  def notify!(skip_channel = nil, only_channel = nil)
    if only_channel
      channels = [only_channel]
    else
      channels = @channels
    end

    channels = channels.reject { |c| c == skip_channel }

    channels.each do |channel|
      yield(channel)
    end
  end

  # Takes in data to be sent to the client and sets up a model to test
  # field permissions against
  def model_for_filter(data)
    klass = Volt::Model.class_at_path([@collection])
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

  def inspect
    "<#{self.class} #{@collection}: #{@query.inspect}>"
  end
end
