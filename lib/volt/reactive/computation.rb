class Computation
  @@current = nil

  def self.current=(val)
    @@current = val
  end

  def self.current
    @@current
  end

  def initialize(invalidate)
    @computations = []
    @invalidate = invalidate
  end

  # Run the invalidate method
  def invalidate!
    @invalidate.call
  end

  # Stop re-run of the computations
  def stop
    raise "not implemented"
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
