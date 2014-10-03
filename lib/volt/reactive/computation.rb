class Computation
  @@current = nil
  @@flush_queue = []


  def self.current=(val)
    @@current = val
  end

  def self.current
    @@current
  end

  def initialize(computation)
    @computation = computation
    @invalidations = []
  end

  # Runs the computation
  def compute!
    @invalidated = false

    unless @stopped

      @computing = true
      run_in do
        @computation.call
      end
      @computing = false
    end
  end

  def on_invalidate(&callback)
    if @invalidated
      # Call invalidate now, since its already invalidated
      Computation.run_without_tracking do
        callback.call
      end
    else
      # Store the invalidation
      @invalidations << callback
    end
  end

  # Calling invalidate removes the computation from all of
  # its dependencies.  This keeps its dependencies from
  # invalidating it again.
  def invalidate!
    unless @invalidated
      @invalidated = true

      if !@stopped && !@computing
        @@flush_queue << self

        # If we are in the browser, we queue a flush for the next tick
        if Volt.in_browser?
          self.class.queue_flush!
        end
      end

      invalidations = @invalidations
      @invalidations = []

      invalidations.each do |invalidation|
        invalidation.call
      end
    end
  end

  # Stop re-run of the computations
  def stop
    unless @stopped
      @stopped = true
      invalidate!
    end
  end

  # Runs in this computation as the current computation, returns the computation
  def run_in
    previous = Computation.current
    Computation.current = self
    yield
    Computation.current = previous

    return self
  end

  def self.run_without_tracking
    previous = Computation.current
    Computation.current = nil
    return_value = yield
    Computation.current = previous

    return return_value
  end


  def self.flush!
    raise "Can't flush while in a flush" if @flushing

    @flushing = true
    # clear any timers
    @timer = nil

    computations = @@flush_queue
    @@flush_queue = []

    computations.each do |computation|
      computation.compute!
    end

    @flushing = false
  end

  def self.queue_flush!
    if !@timer
      # Flush once everything else has finished running
      @timer = `setImmediate(function() { self['$flush!'](); });`
    end
  end
end


class Proc
  def watch!
    return Computation.new(self).run_in do
      # run self
      self.call
    end
  end
end
