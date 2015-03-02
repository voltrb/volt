module Volt
  class Computation
    @@current     = nil
    @@flush_queue = []

    def self.current=(val)
      @@current = val
    end

    def self.current
      @@current
    end

    # @param [Proc] the code to run when the computation needs to compute
    def initialize(computation)
      @computation   = computation
      @invalidations = []
    end

    # Runs the computation, called on initial run and
    # when changed!
    def compute!
      @invalidated = false

      unless @stopped

        @computing = true
        run_in do
          if @computation.arity > 0
            # Pass in the Computation so it can be canceled from within
            @computation.call(self)
          else
            @computation.call
          end
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

        unless @stopped || @computing
          @@flush_queue << self

          # If we are in the browser, we queue a flush for the next tick
          if Volt.in_browser?
            self.class.queue_flush!
          end

          # If we are not in the browser, the user must manually flush
        end

        invalidations  = @invalidations
        @invalidations = []

        invalidations.each(&:call)
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
      previous            = Computation.current
      Computation.current = self
      begin
        yield
      ensure
        Computation.current = previous
      end

      self
    end

    # Run a block without tracking any dependencies
    def self.run_without_tracking
      previous            = Computation.current
      Computation.current = nil
      begin
        return_value        = yield
      ensure
        Computation.current = previous
      end
      return_value
    end

    def self.flush!
      fail "Can't flush while in a flush" if @flushing

      @flushing = true
      # clear any timers
      @timer    = nil

      computations  = @@flush_queue
      @@flush_queue = []

      computations.each(&:compute!)

      @flushing = false
    end

    def self.queue_flush!
      unless @timer
        # Flush once everything else has finished running
        @timer = `setImmediate(function() { self['$flush!'](); });`
      end
    end
  end
end

class Proc
  def watch!
    computation = Volt::Computation.new(self)

    # Initial run
    computation.compute!

    # return the computation
    computation
  end

  # Watches a proc until the value returned equals the passed
  # in value.  When the value matches, the block is called.
  #
  # @param the value to match
  # @return [Volt::Computation] the initial computation is returned.
  def watch_until!(value, &block)
    computation = -> do
      # First fetch the value
      result = self.call

      if result == value
        # Values match

        # call the block
        block.call

        # stop the computation
        computation.stop
      end
    end.watch!

    computation
  end

  # Does an watch and if the result is a promise, resolves the promise.
  # #watch_and_resolve! takes a block that will be passed the resolved results
  # of the proc.
  #
  # Example:
  #   -> { }
  def watch_and_resolve!
    unless block_given?
      raise "watch_and_resolve! requires a block to call when the value is resolved or another value other than a promise is returned in the watch."
    end

    computation = Proc.new do
      result = self.call

      if result.is_a?(Promise)
        result.then do |final|
          yield(final)
        end
      else
        yield(result)
      end
    end.watch!

    # Return the computation
    computation
  end
end
