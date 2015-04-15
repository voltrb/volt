module Volt
  # Included in model's so they can inform the ArrayModel when new listeners are added or removed.
  module ListenerTracker

    # Called when data from this model begins being watched
    def listener_added
      @listener_count ||= 0
      @listener_count += 1
    end

    def listener_removed
      @listener_count ||= 0
      @listener_count -= 1
    end

  end
end