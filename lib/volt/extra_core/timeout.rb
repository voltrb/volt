class Timeout
  def initialize(time=0, &block)
    `setTimeout(function(){#{block.call}}, time)`
  end
end
