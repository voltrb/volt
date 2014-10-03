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
  def initialize
    @dependencies = Set.new
  end

  def depend
    # If there is no @dependencies, don't depend because it has been removed
    return unless @dependencies

    current = Computation.current
    if current
      added = @dependencies.add?(current)

      if added
        # puts "Added #{self.inspect} to #{current.inspect}"
        current.on_invalidate do
          # If @dependencies is nil, this Dependency has been removed
          @dependencies.delete(current) if @dependencies
        end
      end
    end
  end

  def changed!
    deps = @dependencies

    # If no deps, dependency has been removed
    return unless deps

    @dependencies = Set.new

    deps.each do |dep|
      dep.invalidate!
    end
  end

  # Called when a dependency is no longer needed
  def remove
    changed!
    @dependencies = nil
  end
end
