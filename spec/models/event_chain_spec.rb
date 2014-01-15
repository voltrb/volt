require 'volt/models'

describe EventChain do
  before do
    @a = ReactiveValue.new(1)
    @b = ReactiveValue.new(2)    
  end
  
  it "should chain events when we use add_object" do
    
    count = 0
    @b.on('changed') { count += 1 }
    @b.reactive_manager.event_chain.add_object(@a)
    expect(count).to eq(0)
    
    @a.trigger!('changed')
    expect(count).to eq(1)
  end
  
  it "should chain events after add_object is called" do
    @b.reactive_manager.event_chain.add_object(@a)
  
    add_count = 0
    @b.on('added') { add_count += 1 }
    expect(add_count).to eq(0)
    @a.trigger!('added')
    
    expect(add_count).to eq(1) 
  end
  
    
  it "should remove events" do
    @b.reactive_manager.event_chain.add_object(@a)
  
    add_count = 0
    listener = @b.on('added') { add_count += 1 }
    expect(add_count).to eq(0)
    @a.trigger!('added')
    
    expect(add_count).to eq(1)
    
    # Make sure the event is registered
    # TODO: currently fails
    # expect(@a.reactive_manager.listeners.size).to eq(1)
    expect(@b.reactive_manager.event_chain.instance_variable_get('@event_chain').values[0].keys.include?(:added)).to eq(true)
    
    listener.remove
  
    # Make sure its removed
    # TODO: also fails
    # expect(@a.reactive_manager.listeners.size).to eq(0)
    expect(@b.reactive_manager.event_chain.instance_variable_get('@event_chain').values[0].keys.include?(:added)).to eq(false)
    
    @a.trigger!('added')
    expect(add_count).to eq(1)
  end
  
  it "should unchain directly" do
    count = 0
    a = ReactiveValue.new(Model.new)
    b = a._name
    listener = b.on('changed') { count += 1 }
    
    expect(b.reactive_manager.listeners[:changed].size).to eq(1)
    # TODO: ideally this would only bind 1 to a
    expect(a.reactive_manager.listeners[:changed].size).to eq(1)
    
    listener.remove
    
    expect(b.reactive_manager.listeners[:changed]).to eq(nil)
    expect(a.reactive_manager.listeners[:changed]).to eq(nil)
  end
  
  it "should unchain" do
    count = 0
    @b.on('changed') { count += 1 }
    b_object_listener = @b.reactive_manager.event_chain.add_object(@a)
    expect(count).to eq(0)
    
    @a.trigger!('changed')
    expect(count).to eq(1)
    
    b_object_listener.remove
    
    @a.trigger!('changed')
    expect(count).to eq(1)
  end
  
  it "should unchain up the chain" do
    count = 0
    a = ReactiveValue.new(Model.new)
    
    b = a._list
    expect(a.reactive_manager.listeners.size).to eq(0)
    listener = b.on('changed') { count += 1 }
    
    expect(a.reactive_manager.listeners.size).to eq(1)
    
    listener.remove
    
    expect(a.reactive_manager.listeners.size).to eq(0)
  end
  
  describe "double add/removes" do
    it "should unchain" do
      c = ReactiveValue.new(3)
      count = 0
      @b.on('changed') { count += 1 }
      c.on('changed') { count += 1 }
      
      
      # Chain b to a
      b_object_listener = @b.reactive_manager.event_chain.add_object(@a)
      c_object_listener = c.reactive_manager.event_chain.add_object(@a)
      expect(count).to eq(0)
      
      @a.trigger!('changed')
      expect(count).to eq(2)
          
      b_object_listener.remove
          
      @a.trigger!('changed')
      expect(count).to eq(3)
      
      c_object_listener.remove
      
      @a.trigger!('changed')
      expect(count).to eq(3)
    end
  end
end