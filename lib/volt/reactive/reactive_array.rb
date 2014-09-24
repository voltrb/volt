class ReactiveArray# < Array
  def initialize(array=[])
    @array = array
    @array_deps = []
    @size_dep = Dependency.new
    @old_size = 0
  end

  # Forward any missing methods to the array
  def method_missing(method_name, *args, &block)
    @array.send(method_name, *args, &block)
  end

  def ==(*args)
    @array.==(*args)
  end

  # At the moment, each just passes through.
  def each(&block)
    @array.each(&block)
  end

  # TODO: Handle a range
  def [](index)
    # Handle a negative index
    index = size + index if index < 0

    # Get or create the dependency
    dep = (@array_deps[index] ||= Dependency.new)

    # Track the dependency
    dep.depend

    # Return the index
    return @array[index]
  end

  def []=(index, value)

    # Assign the new value
    @array[index] = value

    __trigger_for_index!(index)

    __trigger_size_change!
  end

  # Check to see if the size has changed, trigger a change on size if it has
  def __trigger_size_change!
    new_size = @array.size
    if new_size != @old_size
      @old_size = new_size
      @size_dep.changed!
    end
  end

  def __trigger_for_index!(index)
    # Trigger a change for the cell
    dep = @array_deps[index]
    dep.changed! if dep
  end

  def size
    @size_dep.depend

    return @array.size
  end
  alias :length :size

  def delete_at(index)
    model = @array.delete_at(index_val)

    # Trigger a changed event for each element in the zone where the
    # delete would change
    index.upto(self.size+1) do |position|
      __trigger_for_index!(position)
    end

    __trigger_size_change!

    @persistor.removed(model) if @persistor

    return model
  end


  def delete(val)
    self.delete_at(@array.index(val))
  end

  def clear
    deps = @array_deps
    @array_deps = []

    # Trigger on each cell since we are clearing out the array
    deps.each do |dep|
      dep.changed! if dep
    end

    # clear the array
    @array = []
  end

  # alias :__old_append :<<
  def <<(value)
    result = (@array << value)

    __trigger_for_index!(self.size-1)
    trigger_on_direct_listeners!('added', self.size-1)
    trigger_size_change!

    return result
  end


  def +(array)
    old_size = self.size

    # TODO: += is funky here, might need to make a .plus! method
    result = ReactiveArray.new(@array.dup + array)

    old_size.upto(result.size-1) do |index|
      trigger_for_index!('changed', index)
      trigger_on_direct_listeners!('added', old_size + index)
    end

    trigger_size_change!

    return result
  end

  def insert(index, *objects)
    result = @array.insert(index, *objects)

    # All objects from index to the end have "changed"
    index.upto(result.size-1) do |idx|
      trigger_for_index!('changed', idx)
    end

    objects.size.times do |count|
      trigger_on_direct_listeners!('added', index+count)
    end

    trigger_size_change!

    return result
  end

  def trigger_on_direct_listeners!(event, *args)
    trigger_by_scope!(event, *args) do |scope|
      # Only if it is bound directly to us.  Don't pass
      # down the chain
      !scope || scope[0] == nil
    end

  end

  def trigger_size_change!
    trigger_by_scope!('changed') do |scope|
      # method_name, *args, block = scope
      method_name, args, block = split_scope(scope)

      result = case method_name && method_name.to_sym
      when :size, :length
        true
      else
        false
      end

      result
    end
  end

  # TODO: This is an opal work around.  Currently there is a bug with destructuring
  # method_name, *args, block = scope
  def split_scope(scope)
    if scope
      scope = scope.dup
      method_name = scope.shift
      block = scope.pop

      return method_name, scope, block
    else
      return nil,[],nil
    end
  end

  # Trigger the changed event to any values fetched either through the
  # lookup ([]), #last, or any fetched through the array its self. (sum, max, etc...)
  # On an array, when an element is added or removed, we need to trigger change
  # events on each method that does the following:
  # 1. uses the whole array (max, sum, etc...)
  # 2. accesses this specific element - array[index]
  # 3. accesses an element via a method (first, last)
  def trigger_for_index!(event_name, index, *passed_args)
    self.trigger_by_scope!(event_name, *passed_args) do |scope|
      # method_name, *args, block = scope
      method_name, args, block = split_scope(scope)

      result = case method_name
      when nil
        # no method name means the event was bound directly, we don't
        # want to trigger changed on the array its self.
        false
      when :[]
        # Extract the current index if its reactive
        arg_index = args[0].cur

        # TODO: we could handle negative indicies better
        arg_index == index.cur || arg_index < 0
      when :last
        index.cur == self.size-1
      when :first
        index.cur == 0
      when :size, :length
        # Size does not depend on the contents of the cells
        false
      else
        true
      end

      result = false if method_name == :reject

      result
    end
  end

  def inspect
    "#<#{self.class.to_s}:#{object_id} #{@array.inspect}>"
  end

  # tag_method(:count) do
  #   destructive!
  # end
  def count(*args, &block)
    # puts "GET COUNT"
    if block
      run_block = Proc.new do |source|
        count = 0
        source.cur.size.times do |index|
          val = source[index]
          result = block.call(val).cur
          if result == true
            count += 1
          end
        end

        count
      end

      return ReactiveBlock.new(self, block, run_block)
    else
      @array.count(*args)
    end
  end

  def reject(*args, &block)
    if block
      run_block = Proc.new do |source|
        puts "RUN REJECT"
        new_array = []
        source.cur.size.times do |index|
          val = source[index]
          result = block.call(val).cur
          if result != true
            new_array << val.cur
          end
        end

        ReactiveArray.new(new_array)
      end

      return ReactiveBlock.new(self, block, run_block)
    else
      @array.count
    end
  end

  private

    def __clear_element(index)
      # Cleanup any tracking on an index
      if @reactive_element_listeners && self[index].reactive?
        @reactive_element_listeners[index].remove
        @reactive_element_listeners.delete(index)
      end
    end

    def __track_element(index, value)
      __setup_tracking(index, value) do |event, index, args|
        trigger_for_index!(event, index, *args)
      end
    end

end
