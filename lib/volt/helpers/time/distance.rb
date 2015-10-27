module Volt
  class Duration
    UNIT_MAP = {
      :years => 31536000,
      :months => 2592000,
      :weeks => 604800,
      :days => 86400,
      :hours => 3600,
      :minutes => 60,
      :seconds => 1
    }

    # Returns a string representation of the duration.
    #
    # @param How many places in time units to show.
    # @param The minimum unit to show, anything below will be ignored.  Results
    #        will be rounded up the the nearest min_unit.
    def duration_in_words(places=2, min_unit=:minutes, recent_message='just now')
      parts = []
      secs = to_i
      UNIT_MAP.each_pair do |unit, count|
        val = (secs / count).floor
        secs = secs % count

        parts << [val, unit] if val > 0
        break if unit == min_unit
      end

      # Trim number of units
      parts = parts.take(places) if places

      parts = parts.map do |val, unit|
        pl_units = val == 1 ? unit.singularize : unit
        "#{val} #{pl_units}"
      end

      # Round up to the nearest unit
      if parts.size == 0
        parts << recent_message
      end

      parts.to_sentence
    end
  end
end

class VoltTime
  def time_distance_in_words(from_time=VoltTime.live_now(60), places=2, min_unit=:minutes, recent_message='just now')
    dist = from_time - self

    direction = dist >= 0 ? 'ago' : 'from now'

    duration = dist.abs.seconds

    dist_in_words = duration.duration_in_words(places, min_unit, recent_message)

    unless dist_in_words == recent_message
      dist_in_words += ' ' + direction
    end

    dist_in_words
  end
end