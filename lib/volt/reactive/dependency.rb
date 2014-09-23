# Temp until https://github.com/opal/opal/pull/596
require 'set'

class Set
  def delete(o)
    @hash.delete(o)
  end

  def delete?(o)
    if include?(o)
      delete(o)
    else
      nil
    end
  end

  def delete_if
    block_given? or return enum_for(__method__)
    # @hash.delete_if should be faster, but using it breaks the order
    # of enumeration in subclasses.
    select { |o| yield o }.each { |o| @hash.delete(o) }
    self
  end

  def to_a
    @hash.keys
  end
end

class Dependency
  @@flush_queue = []
  if RUBY_PLATFORM == 'opal'
    @@in_browser = `!!document`
  else
    @@in_browser = false
  end

  def initialize
    @dependencies = Set.new
  end

  def depend
    current = Computation.current
    if current
      added = @dependencies.add?(current)

      if added
        current.on_invalidate do
          @dependencies.delete(current)
        end
      end
    end
  end

  def changed!
    deps = @dependencies
    @dependencies = Set.new

    @@flush_queue += deps.to_a

    # If we are in the browser, we queue a flush for the next tick
    if @@in_browser
      self.class.queue_flush!
    end
  end

  # Called when a dependency is no longer needed
  def remove
    @dependencies = nil
  end

  def self.flush!
    # clear any timers
    @timer = nil

    computations = @@flush_queue
    @@flush_queue = []

    computations.each do |computation|
      computation.compute!
    end
  end

  def self.queue_flush!
    unless @timer
      # Flush once everything else has finished running
      @timer = `setTimeout(function() { self['$flush!'](); }, 0);`
    end
  end
end
