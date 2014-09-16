class Dependency
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

    deps.each do |computation|
      computation.run_in do
        computation.invalidate!
      end
    end
  end
end
