# The draw cycle is responsible for queueing redraws until all of the events have
# fired.  Once that is done, everything will be redrawn.  This prevents bindings
# from being drawn multiple times before all events have propigated.
class DrawCycle
  def initialize
    @queue = {}
    @timer = nil
  end

  def queue(binding)
    @queue[binding] = true

    unless @timer
      # Flush once everything else has finished running
      @timer = `setTimeout(function() { self.$flush(); }, 0);`
    end
  end

  def flush
    @timer = nil

    work_queue = @queue
    @queue = {}

    work_queue.each_pair do |binding,_|
      # Call the update if queued
      binding.update
    end

  end
end
