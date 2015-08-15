# QueryDiff takes the results of a query and compares it to the previous
# run.  It builds a diff that can be used to update, insert, and move models
# to bring things up to date on the client.

module Volt
  class QueryDiff
    # @param - initial run of the query(s)
    # @param - is an array of symbols (or array of arrays of symbols) that
    #          represent the associations:
    #          Example: [:comments, [:comments, :user]]
    def initialize(start_data, associations=[])
      @old_data = start_data
      @old_ids = start_data.map {|v| v[:id] }
      @old_data_hash = hash_data(start_data)

      @associations = associations
    end

    # returns the data keyed by id for faster lookup
    def hash_data(array)
      Hash[array.map { |r| [r[:id], r] }]
    end

    def run(new_data)
      @new_data = new_data
      @new_data_hash = hash_data(new_data)
      @new_ids = new_data.map {|v| v[:id] }

      @diff = []

      detect_removed
      detect_added_and_moved
      detect_changed

      @old_data = new_data
      @old_data_hash = @new_data_hash
      @old_ids = @new_ids

      # return diff
      @diff
    end

    def detect_removed
      # Removed models
      removed_ids = @old_ids - @new_ids
      if removed_ids.size > 0
        removed_ids.each do |r_id|
          @diff << ['r', r_id]
        end
      end

      # Update @old_ids to relect the removed
      @old_ids &= @new_ids
    end

    # Loop through the new list, tracking in the old, notifies of any that
    # have been added or moved.
    def detect_added_and_moved
      previous_index = 0

      # we'll mutate the old_ids as we move through them to make it easier.
      old_ids = @old_ids.dup
      @new_ids.each_with_index do |id, index|
        if (cur_previous = old_ids[previous_index]) && cur_previous == id
          # Same in both previous and new
          previous_index += 1
          next
        end

        # We have an item that didn't match the current position's previous
        # TODO: make a hash so we don't have to do include?
        if old_ids.include?(id)
          # The location from the previous has changed, move to correct location.

          # Remove from old_idss, as it will be moved and we will be past it.
          old_ids.delete(id)
          @diff << ['m', id, index]
        else
          # Check for inserts
          # TODO: Faster lookup
          data = @new_data_hash[id]
          @diff << ['i', index, data]
        end
      end
    end

    # Finds all items in the previous results that have new values, and alerts
    # of changes.
    def detect_changed
      not_added_or_removed = @old_ids & @new_ids

      not_added_or_removed.each do |id|
        if @old_data_hash[id] != (data = @new_data_hash[id])
          # Data hash changed
          @diff << ['c', id, data]
        end
      end
    end
  end
end