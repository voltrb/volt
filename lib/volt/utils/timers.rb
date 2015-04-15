module Volt

  # The timers class provides useful methods for working in an asynchronus environment.
  class Timers
    # next tick (same as setImmediate) calls the block of code after any currently
    # running code is finished.
    def self.next_tick(&block)
      if Volt.in_browser?
        `setImmediate(function() {`
          yield
        `})`
      else
        tick_timers = (Thread.current['tick_timers'] ||= [])
        tick_timers << block
      end
    end

    # On the server, we need to manually flush next tick timers.
    # This is done automatically in the console after each enter.
    def self.flush_next_tick_timers!
      tick_timers = Thread.current['tick_timers']

      if tick_timers
        # clear
        Thread.current['tick_timers'] = nil
        tick_timers.each do |timer|
          # Run the timer
          timer.call
        end
      end
    end
  end
end