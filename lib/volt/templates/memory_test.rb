require 'opal'
require 'volt/models'

class Test
  def self.test1
    a = ReactiveValue.new(1)
    listener = a.on('changed') { puts "CHANGED" }
    a.cur = 5
    listener.remove
    
    ObjectTracker.process_queue
  end
  
  def self.test
    a = ReactiveValue.new(Model.new)
    a._cool = [1,2,3]
    
    listener = a._cool.on('added') { puts "ADDED" }
    a._cool << 4
    puts a._cool[3]
    
    listener.remove
    
    ObjectTracker.process_queue
  end
end