module Volt
  # EventCounter has an #add and #remove method, and when the first one is added
  # will call the #start proc (passed to new), and when the last is removed will
  # call #stop.
  class EventCounter
    attr_reader :count

    def initialize(start, stop)
      @start = start
      @stop = stop

      @count = 0
    end

    def add
      @count += 1

      @start.call if @count == 1
    end

    def remove
      @count -= 1

      raise "count below 0" if @count < 0

      @stop.call if @count == 0
    end
  end
end