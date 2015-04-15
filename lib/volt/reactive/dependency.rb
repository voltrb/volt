# Temp until https://github.com/opal/opal/pull/596
require 'set'

class Set
  def delete(o)
    if include?(o)
      @hash.delete(o)
      true
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

module Volt
  # Dependencies are used to track the current computation so it can be re-run
  # at a later point if this dependency changes.
  #
  # You can also pass an on_dep and on_stop_dep proc's to #initialize.
  class Dependency
    # Setup a new dependency.
    #
    # @param on_dep [Proc] a proc to be called the first time a computation depends
    #   on this dependency.
    # @param on_stop_dep [Proc] a proc to be called when no computations are depending
    #   on this dependency anymore.
    def initialize(on_dep=nil, on_stop_dep=nil)
      @dependencies = Set.new
      @on_dep = on_dep
      @on_stop_dep = on_stop_dep
    end

    def depend
      # If there is no @dependencies, don't depend because it has been removed
      return unless @dependencies

      current = Computation.current
      if current
        added = @dependencies.add?(current)

        if added
          # The first time the dependency is depended on by this computation, we call on_dep
          @on_dep.call if @on_dep && @dependencies.size == 1

          current.on_invalidate do
            # If @dependencies is nil, this Dependency has been removed
            if @dependencies
              # For set, .delete returns a boolean if it was deleted
              deleted = @dependencies.delete(current)

              # Call on stop dep if no more deps
              @on_stop_dep.call if @on_stop_dep && deleted && @dependencies.size == 0
            end
          end
        end
      end
    end

    def changed!
      deps = @dependencies

      # If no deps, dependency has been removed
      return unless deps

      @dependencies = Set.new

      deps.each(&:invalidate!)

      @on_stop_dep.call if @on_stop_dep
    end

    # Called when a dependency is no longer needed
    def remove
      changed!
      @dependencies = nil
    end
  end
end
