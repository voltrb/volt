module Volt
  # Included in model's so they can inform the ArrayModel when new listeners are added or removed.
  module ListenerTracker

    # Called when data from this model begins being watched
    def listener_added
      @listener_count ||= 0
      @listener_count += 1

      puts "ADDED #{@listener_count}"
    end

    def listener_removed
      @listener_count ||= 0
      @listener_count -= 1

      puts "REMOVED #{@listener_count}"
    end

  end
end