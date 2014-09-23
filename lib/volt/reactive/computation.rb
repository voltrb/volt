class Computation
  @@current = nil

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
    unless @stopped
      run_in do
        @computation.call
      end
    end
  end

  def on_invalidate(callback)
    @invalidations << callback
  end

  # Calling invalidate removes the computation from all of
  # its dependencies.  This keeps its dependencies from
  # invalidating it again.
  def invalidate!
    @invalidations.each do |invalidation|
      invalidation.call
    end
  end

  # Stop re-run of the computations
  def stop
    @stopped = true
    invalidate!
    # raise "not implemented"
  end

  # Runs in this computation as the current computation, returns the computation
  def run_in
    previous = Computation.current
    Computation.current = self
    yield
    Computation.current = previous

    return self
  end
end


class Proc
  def bind!
    return Computation.new(self).run_in do
      # run self
      self.call
    end
  end
end
