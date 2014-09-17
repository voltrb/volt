class Dependency
  @@flush_queue = []
  if RUBY_PLATFORM == 'opal'
    @@in_browser = `!!document`
  else
    @@in_browser = false
  end

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

    # If we are in the browser, we queue a flush for the next tick
    if @@in_browser
      self.class.queue_flush!
    end
  end

  def self.flush!
    # clear any timers
    @timer = nil

    computations = @@flush_queue
    @@flush_queue = []

    computations.each do |computation|
      computation.run_in do
        computation.invalidate!
      end
    end
  end

  def self.queue_flush!
    unless @timer
      # Flush once everything else has finished running
      @timer = `setTimeout(function() { self['$flush!'](); }, 0);`
    end
  end
end
