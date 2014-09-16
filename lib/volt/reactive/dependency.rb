class Dependency
  @@flush_queue = []

  def initialize
    @dependencies = []
  end

  def depend
    current = Computation.current
    @dependencies << current if current
  end

  def changed!
    deps = @dependencies
    @dependencies = []

    @@flush_queue += deps
  end

  def self.flush!
    computations = @@flush_queue
    @@flush_queue = []

    computations.each do |computation|
      computation.run_in do
        computation.invalidate!
      end
    end
  end
end
