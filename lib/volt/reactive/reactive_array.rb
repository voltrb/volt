require 'volt/reactive/object_tracking'
require 'volt/reactive/reactive_count'

class ReactiveArray# < Array
  include ReactiveTags
  include ObjectTracking

  def initialize(array=[])
    @array = array
  end

  # Forward any missing methods to the array
  def method_missing(method_name, *args, &block)
    @array.send(method_name, *args, &block)
  end

  def ==(*args)
    @array.==(*args)
  end

  tag_method(:each) do
    destructive!
  end
  # At the moment, each just passes through.
  def each(&block)
    @array.each(&block)
  end

  tag_method(:[]=) do
    pass_reactive!
  end

  # alias :__old_assign :[]=
  def []=(index, value)
    index_val = index.cur
    # Clean old value
    __clear_element(index)

    @array[index.cur] = value

    # Track new value
    __track_element(index, value)

    # Also track the index if its reactive
    if index.reactive?
      # TODO: Need to clean this up when the index changes
      event_chain.add_object(index.reactive_manager) do |event, *args|
        trigger_for_index!(event, index.cur)
      end
    end

    # Trigger changed
    trigger_for_index!('changed', index_val)
  end

  tag_method(:delete_at) do
    destructive!
  end
  # alias :__old_delete_at :delete_at
  def delete_at(index)
    index_val = index.cur

    __clear_element(index)

    model = @array.delete_at(index_val)

    trigger_on_direct_listeners!('removed', index_val)

    # Trigger a changed event for each element in the zone where the
    # lookup would change
    index.upto(self.size+1) do |position|
      trigger_for_index!('changed', position)
    end

    trigger_size_change!

    @persistor.removed(model) if @persistor

    return model
  end


  # Delete is implemented as part of delete_at
  tag_method(:delete) do
    destructive!
  end
  def delete(val)
    self.delete_at(@array.index(val))
  end

  # Removes all items in the array model.
  tag_method(:clear) do
    destructive!
  end
  def clear
    @array = []
    trigger!('changed')
  end

  tag_method(:<<) do
    pass_reactive!
  end
  # alias :__old_append :<<
  def <<(value)
    result = (@array << value)

    # Track new value
    __track_element(self.size-1, value)

    trigger_for_index!('changed', self.size-1)
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

  tag_method(:insert) do
    destructive!
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
      # puts "SCOPE CHECK: TFI: #{method_name.inspect} - #{args.inspect} on #{self.inspect}"

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

      result
    end
  end

  def inspect
    "#<#{self.class.to_s} #{@array.inspect}>"
  end


  tag_method(:count) do
    destructive!
  end
  def count(&block)
    return ReactiveCount.new(self, block)
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
