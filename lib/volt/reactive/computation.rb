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
        # Computation.run_without_tracking do
        queue_flush!
        callback.call
        # end
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

        queue_flush! unless @stopped

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
      @@timer    = nil

      computations  = @@flush_queue
      @@flush_queue = []

      computations.each(&:compute!)

      @flushing = false
    end

    def queue_flush!
      @@flush_queue << self

      # If we are in the browser, we queue a flush for the next tick
      # If we are not in the browser, the user must manually flush
      if Volt.in_browser?
        unless @@timer
          # Flush once everything else has finished running
          @@timer = `setImmediate(function() { self.$class()['$flush!'](); })`
        end
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
    computation = proc do |comp|
      # First fetch the value
      result = call

      if result == value
        # Values match

        # call the block
        Volt::Computation.run_without_tracking do
          block.call
        end

        # stop the computation
        comp.stop
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
  def watch_and_resolve!(yield_nil_for_unresolved_promise=false)
    unless block_given?
      fail 'watch_and_resolve! requires a block to call when the value is resolved or another value other than a promise is returned in the watch.'
    end

    # Keep results between runs
    result = nil

    computation = proc do
      result = call
      last_promise = nil

      if result.is_a?(Promise)
        last_promise = result

        # Often you want a to be alerted that an unresolved promise is waiting
        # to be resolved.
        if yield_nil_for_unresolved_promise && !result.resolved?
          yield(nil)
        end

        result.then do |final|
          # Check to make sure that a new value didn't get reactively pushed
          # before the promise resolved.
          if last_promise.is_a?(Promise) && last_promise == result
            yield(final)

            # Clear result for GC
            result = nil
          end
        end
      else
        yield(result)

        # Clear result for GC
        result = nil
      end
    end.watch!

    # Return the computation
    computation
  end
end
