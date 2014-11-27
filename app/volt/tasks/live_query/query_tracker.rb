# The query tracker runs queries and then tracks the changes
# that take place.
class QueryTracker
  attr_accessor :results

  def initialize(live_query, data_store)
    @live_query = live_query
    @data_store = data_store

    # Stores the list of id's currently associated with this query
    @current_ids = []
    @results = []
    @results_hash = {}
  end

  # Runs the query, stores the results and updates the current_ids
  def run(skip_channel = nil)
    @previous_results = @results
    @previous_results_hash = @results_hash
    @previous_ids = @current_ids

    # Run the query again
    @results = @data_store.query(@live_query.collection, @live_query.query)

    # Update the current_ids
    @current_ids = @results.map { |r| r['_id'] }
    @results_hash = Hash[@results.map { |r| [r['_id'], r] }]

    process_changes(skip_channel)
  end

  # Looks at the changes in the last run and sends out notices
  # all changes.
  def process_changes(skip_channel)
    return unless @previous_ids

    detect_removed(skip_channel)
    detect_added_and_moved(skip_channel)
    detect_changed(skip_channel)
  end

  def detect_removed(skip_channel)
    # Removed models
    removed_ids = @previous_ids - @current_ids
    if removed_ids.size > 0
      @live_query.notify_removed(removed_ids, skip_channel)
    end

    # Update @previous_ids to relect the removed
    @previous_ids &= @current_ids
  end

  # Loop through the new list, tracking in the old, notifies of any that
  # have been added or moved.
  def detect_added_and_moved(skip_channel)
    previous_index = 0
    @current_ids.each_with_index do |id, index|
      if (cur_previous = @previous_ids[previous_index]) && cur_previous == id
        # Same in both previous and new
        previous_index += 1
        next
      end

      # We have an item that didn't match the current position's previous
      # TODO: make a hash so we don't have to do include?
      if @previous_ids.include?(id)
        # The location from the previous has changed, move to correct location.

        # Remove from previous_ids, as it will be moved and we will be past it.
        @previous_ids.delete(id)
        @live_query.notify_moved(id, index, skip_channel)
      else
        # TODO: Faster lookup
        data = @results_hash[id]
        @live_query.notify_added(index, data, skip_channel)
      end
    end
  end

  # Finds all items in the previous results that have new values, and alerts
  # of changes.
  def detect_changed(skip_channel)
    not_added_or_removed = @previous_ids & @current_ids

    not_added_or_removed.each do |id|
      if @previous_results_hash[id] != (data = @results_hash[id])
        # Data hash changed
        @live_query.notify_changed(id, data, skip_channel)
      end
    end
  end
end
