class ReactiveCount
  include ReactiveTags

  def reactive?
    true
  end

  def initialize(source, block)
    @source = ReactiveValue.new(source)
    @block = block
  end

  def cur
    direct_count
  end

  # After events are bound, we keep a cache of each cell's count
  # value, and base the results
  def cached_count
    @cached_results = []


  end

  # Before events are bound, when .cur is called, we simply
  # run the count on the source object.
  def direct_count
    count = 0
    @source.cur.size.times do |index|
      val = @source[index]
      result = @block.call(val).cur
      if result == true
        count += 1
      end
    end

    count
  end

  def setup_listeners
    @cell_trackers = []
    @setup = false
    @added_tracker = @source.on('added') do |_, index|
      change_cell_count(@source.size.cur)
    end

    @removed_tracker = @source.on('removed') do |_, index|
      change_cell_count(@source.size.cur)
    end

    @setup = true

    # Initial cell tracking
    change_cell_count(@source.size.cur)
  end

  # We need to make sure we're listening on the result from each cell,
  # that way we can trigger when the value changes.
  def change_cell_count(size)
    # puts "CHANGE SIZE: #{size}"
    current_size = @cell_trackers.size

    if current_size < size
      # Add trackers

      current_size.upto(size-1) do |index|
        # Get the reactive value for the index
        val = @source[index]

        result = @block.call(val)

        @cell_trackers << result.on('changed') do
          # puts "RESULT CHANGED: #{index}"
          trigger!('changed')
        end
      end
    elsif current_size > size
      (current_size-1).downto(size) do |index|
        @cell_trackers[index].remove
        @cell_trackers.delete_at(index)
      end
    end
  end


  def teardown_listeners
    @added_tracker.remove
    @added_tracker = nil

    @removed_tracker.remove
    @removed_tracker = nil

    change_cell_count(0)

    @cell_trackers = nil
  end

  def event_added(event, scope_provider, first, first_for_event)
    setup_listeners if first
  end

  def event_removed(event, last, last_for_event)
    teardown_listeners if last
  end

  def inspect
    "@#{cur}"
  end
end