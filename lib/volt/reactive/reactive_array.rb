require 'volt/reactive/eventable'

module Volt
  class ReactiveArray
    include Eventable

    def initialize(array = [])
      @array      = array
      @array_deps = []
      @size_dep   = Dependency.new
      @old_size   = 0
    end

    def respond_to_missing?(method_name, include_private = false)
      @array.respond_to?(method_name, include_private) || super
    end

    # Forward any missing methods to the array
    def method_missing(method_name, *args, &block)
      # Long term we should probably handle all Enum methods
      # directly for smarter updating.  For now, just depend on size
      # so updates retrigger the whole method call.
      @size_dep.depend
      @array.send(method_name, *args, &block)
    end

    def ==(*args)
      @array.==(*args)
    end

    # At the moment, each just passes through.
    def each(&block)
      @array.each(&block)
    end

    def empty?
      @size_dep.depend
      @array.empty?
    end

    def count(&block)
      if block
        count = 0

        Volt.run_in_mode(:no_model_promises) do
          size.times do |index|
            count += 1 if block.call(self[index])
          end
        end

        # return as a promise
        count.then
      else
        size
      end
    end

    def select
      result = []
      size.times do |index|
        val = self[index]
        result << val if yield(val)
      end

      result
    end

    def any?
      if block_given?
        size.times do |index|
          val = self[index]

          return true if yield(val)
        end

        false
      else
        @array.any?
      end
    end

    def all?
      if block_given?
        size.times do |index|
          val = self[index]

          return false unless yield(val)
        end

        true
      else
        @array.all?
      end
    end

    def last
      self[-1]
    end

    # TODO: Handle a range
    def [](index)
      # Handle a negative index, depend on size
      if index < 0
        # Depend on size by calling .size, since we are looking up reverse
        # indexes

        # cache size lookup
        size = self.size

        index = size + index

        # In this case, we're looking back past 0 (going backwards), so we get
        # nil.  Since we're depending on @size_dep (because we called .size),
        # it will invalidate when the size changes.
        return nil if index < 0
      end

      # Get or create the dependency
      dep   = (@array_deps[index] ||= Dependency.new)

      # Track the dependency
      dep.depend

      # Return the index
      @array[index]
    end

    def []=(index, value)
      # Assign the new value
      @array[index] = value

      trigger_for_index!(index)

      trigger_size_change!
    end

    def size
      @size_dep.depend

      @array.size
    end

    alias_method :length, :size

    def delete_at(index, skip_persistor=false)
      size = @array.size
      # Handle a negative index
      index = size + index if index < 0

      model = @array.delete_at(index)

      # Remove the dependency for that cell, and #remove it
      index_deps = @array_deps.delete_at(index)
      index_deps.remove if index_deps

      trigger_removed!(index)

      # Trigger a changed event for each element in the zone where the
      # delete would change
      index.upto(size + 1) do |position|
        trigger_for_index!(position)
      end

      trigger_size_change!

      @persistor.removed(model) if @persistor && !skip_persistor

      model
    end

    def delete(val)
      index = @array.index(val)
      if index
        delete_at(index)
      else
        # Sometimes the model isn't loaded at the right state yet, so we
        # just remove it from the persistor
        @persistor.removed(val) if @persistor
      end
    end

    def clear
      __clear

      @persistor.clear if @persistor
    end

    # alias :__old_append :<<
    def <<(*args)
      append(*args)
    end

    def append(value)
      result = (@array << value)

      trigger_for_index!(@array.size - 1)
      trigger_added!(@array.size - 1)
      trigger_size_change!

      result
    end

    def +(array)
      fail 'not implemented yet'
      old_size = @array.size

      # TODO: += is funky here, might need to make a .plus! method
      result   = ReactiveArray.new(@array.dup + array)

      old_size.upto(result.size - 1) do |index|
        trigger_for_index!('changed', index)
        trigger_added!(old_size + index)
      end

      trigger_size_change!

      result
    end

    def insert(index, *objects)
      result = @array.insert(index, *objects)

      # All objects from index to the end have "changed"
      index.upto(result.size) do |index|
        trigger_for_index!(index)
      end

      objects.size.times do |count|
        trigger_added!(index + count)
      end

      trigger_size_change!

      result
    end

    def inspect
      # TODO: should also depend on items in array
      @size_dep.depend
      "#<#{self.class}:#{object_id} #{@array.inspect}>"
    end

    private

    # used internally, clears out the array, triggers the change events, but
    # does not call clear on the persistors.  Used when models are updated
    # externally.
    def __clear
      old_size = @array.size

      deps        = @array_deps
      @array_deps = []

      # Trigger remove for each cell
      old_size.times do |index|
        trigger_removed!(old_size - index - 1)
      end

      # Trigger on each cell since we are clearing out the array
      if deps
        deps.each do |dep|
          dep.changed! if dep
        end
      end

      # clear the array
      @array = []
    end

    # Check to see if the size has changed, trigger a change on size if it has
    def trigger_size_change!
      new_size = @array.size
      if new_size != @old_size
        @old_size = new_size
        @size_dep.changed!
      end
    end

    def trigger_for_index!(index)
      # Trigger a change for the cell
      dep = @array_deps[index]
      dep.changed! if dep
    end

    def trigger_added!(index)
      trigger!('added', index)
    end

    def trigger_removed!(index)
      trigger!('removed', index)
    end
  end
end
