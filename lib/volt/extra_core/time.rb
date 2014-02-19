class Temp1
  include Events

  attr_accessor :seconds
  def initialize
    @seconds = ReactiveValue.new(nil)
  end

  def seconds=(val)
    @seconds.cur = val
  end

  def live_seconds
    @seconds
  end
end
