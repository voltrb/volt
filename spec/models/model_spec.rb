require 'volt/models'

describe Model do
  
  it "should allow _ methods to be used to store values without predefining them" do
    a = Model.new
    a._stash = 'yes'
  
    expect(a._stash).to eq('yes')
  end
  
  it "should update other values off the same model" do
    a = ReactiveValue.new(Model.new)
    count = 0
    a._name.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._name = 'Bob'
    expect(count).to eq(1)
  end
  
  it "should say unregistered attributes are nil" do
    a = ReactiveValue.new(Model.new)
    b = a._missing == nil
    expect(b.cur).to eq(true)
  end
  
  it "should negate nil and false correctly" do
    a = ReactiveValue.new(Model.new)
    expect((!a._missing).cur).to eq(true)
    
    a._mis1 = nil
    a._false1 = false
    
    expect((!a._mis1).cur).to eq(true)
    expect((!a._false1).cur).to eq(true)
  end
  
  it "should return a nil model for an underscore value that doesn't exist" do
    a = Model.new
    expect(a._something.cur.attributes).to eq(nil)
  end
  
  it "should let you bind before something is defined" do
    a = ReactiveValue.new(Model.new)
    
    b = a._one + 5
    expect(b.cur.class).to eq(NoMethodError)
    
    count = 0
    b.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._one = 1
    expect(count).to eq(1)
    expect(b.cur).to eq(6)
  end
  
  it "should let you access an array element before its defined" do
    # TODO: ...
  end
  
  it "should trigger changed once when a new value is assigned." do
    a = ReactiveValue.new(Model.new)
  
    count = 0
    a._blue.on('changed') { count += 1 }
    
    a._blue = 'one'
    expect(count).to eq(1)
    a._blue = 'two'
    expect(count).to eq(2)
  end
  
  it "should not call changed on other attributes" do
    a = ReactiveValue.new(Model.new)
    
    count = 0
    a._blue.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._green = 'one'
    expect(count).to eq(0)
    
    a._blue = 'two'
    expect(count).to eq(1)
    
  end
  
  it "should call change through arguments" do
    a = ReactiveValue.new(Model.new)
    a._one = 1
    a._two = 2
    
    c = a._one + a._two
    
    count = 0
    c.on('changed') { count += 1}
    expect(count).to eq(0)
    
    a._two = 5
    expect(count).to eq(1)
    
    expect(c.cur).to eq(6)    
  end
  
  it "should store reactive values in arrays and trigger updates when those values change" do
    a = ReactiveValue.new(Model.new)
    b = ReactiveValue.new('blue')
    a._one = 1
    a._items << 0
    
    count_1 = 0
    a._items[1].on('changed') { count_1 += 1 }
    expect(count_1).to eq(0)
      
    a._items <<  b
    expect(count_1).to eq(1)
    
    b.cur = 'update'
    expect(count_1).to eq(2)
    
    count_2 = 0
    a._items[2].on('changed') { count_2 += 1 }
    expect(count_2).to eq(0)
    
    a._items << a._one
    expect(count_2).to eq(1)
    
    a._one = 'updated'
    expect(count_1).to eq(2)
    expect(count_2).to eq(2)
  end
  
  it "should let you register events before it expands" do
    a = ReactiveValue.new(Model.new)
    count = 0
    a._something.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._something = 20
    expect(count).to eq(1)
  end
  
  it "should trigger changed through concat" do
    model = ReactiveValue.new(Model.new)
    
    concat = model._one + model._two
    
    count = 0
    concat.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    model._one = 'one'
    expect(count).to eq(1)
    
    model._two = 'two'
    expect(count).to eq(2)
    
    expect(concat.cur).to eq('onetwo')
  end
  
  it "should allow a reactive value to be assigned as a value in a model" do
    model = ReactiveValue.new(Model.new)
    
    model._items << {_name: 'One'}
    model._items << {_name: 'Two'}
  
    current = model._items[model._index]
    
    model._current_item = current
  end
  
  it "should trigger changed for any indicies after a deleted index" do
    model = ReactiveValue.new(Model.new)
    
    model._items << {_name: 'One'}
    model._items << {_name: 'Two'}
    model._items << {_name: 'Three'}
  
    count = 0
    model._items[2].on('changed') { count += 1 }
    expect(count).to eq(0)
    
    model._items.delete_at(1)
    expect(count).to eq(1)
  end
  
  it "should change the size and length when an item gets added" do
    model = ReactiveValue.new(Model.new)
    
    model._items << {_name: 'One'}
    size = model._items.size
    length = model._items.length
    
    count_size = 0
    count_length = 0
    size.on('changed') { count_size += 1 }
    length.on('changed') { count_length += 1 }
    expect(count_size).to eq(0)
    expect(count_length).to eq(0)
    
    model._items << {_name: 'Two'}
    expect(count_size).to eq(1)
    expect(count_length).to eq(1)
  end
  
  it "should add doubly nested arrays" do
    model = ReactiveValue.new(Model.new)
    
    model._items << {_name: 'Cool', _lists: []}
    model._items[0]._lists << {_name: 'worked'}
    expect(model._items[0]._lists[0]._name.cur).to eq('worked')
  end
  
  it "should make pushed subarrays into ArrayModels" do
    model = ReactiveValue.new(Model.new)
    
    model._items << {_name: 'Test', _lists: []}
    expect(model._items[0]._lists.cur.class).to eq(ArrayModel)
  end
  
  it "should make assigned subarrays into ArrayModels" do
    model = ReactiveValue.new(Model.new)
    
    model._item._name = 'Test'
    model._item._lists = []
    expect(model._item._lists.cur.class).to eq(ArrayModel)    
  end
  
  it "should call changed when a the reference to a submodel is assigned to another value" do
    a = ReactiveValue.new(Model.new)
    
    count = 0
    a._blue._green.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._blue._green = 5
    expect(count).to eq(1)
    
    a._blue = 22
    expect(count).to eq(2)
  end
  
  it "should trigger changed when a value is deleted" do
    a = ReactiveValue.new(Model.new)
    
    count = 0
    a._blue.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._blue = 1
    expect(count).to eq(1)
    
    a.delete(:_blue)
    expect(count).to eq(2)
  end
  
  it "should not trigger a change if the new value is exactly the same" do
    
  end
  
  it "should let you append nested hashes" do
    a = Model.new
    # TODO: Fails
    # a._items << {_name: {_text: 'Name'}}
  end
  
  it "should work" do
    store = ReactiveValue.new(Model.new)
    # params = ReactiveValue.new(Params.new)
    index = ReactiveValue.new(0)
    
    a = store._todo_lists
    store._current_todo = a#[index]
    
    added_count = 0
    changed_count = 0
    # store._todo_lists.on('added') { added_count += 1 }
    store._current_todo.on('changed') { changed_count += 1 }
    # expect(added_count).to eq(0)
    expect(changed_count).to eq(0)
  
    a.cur = 1000
    # store._todo_lists << {_name: 'List 1', _todos: []}
    
    
    # store._todo_lists[0]._todos << {_name: 'Todo 1'}
    
    # expect(added_count).to eq(1)
    # expect(changed_count).to eq(1)
  end
  
  it "should handle a basic todo list with no setup" do
    store = ReactiveValue.new(Model.new)
    params = ReactiveValue.new(Model.new({}, persistor: Persistors::Params))
    
    a = store._todo_lists
    store._current_todo = store._todo_lists[params._index.or(0).to_i]
    
    added_count = 0
    changed_count = 0
    store._todo_lists.on('added') { added_count += 1 }
    store._current_todo.on('changed') { changed_count += 1 }
    expect(added_count).to eq(0)
    expect(changed_count).to eq(0)
  
    store._todo_lists << {_name: 'List 1', _todos: []}
    store._todo_lists[0]._todos << {_name: 'Todo 1'}
    
    expect(added_count).to eq(1)
    # expect(changed_count).to eq(1)
  end
  
  it "should not call added too many times" do
    a = ReactiveValue.new(Model.new)
    a._list << 1
    ac = a._current_list = a._list[0]
    
    count = 0
    passed_count = 0
    a._list.on('added') { count += 1 }
    a._current_list.on('added') { passed_count += 1 }
    expect(count).to eq(0)
    expect(passed_count).to eq(0)
    
    a._list << 2
    expect(count).to eq(1)
    expect(passed_count).to eq(0)
  end
  
  it "should propigate to different branches" do
    a = ReactiveValue.new(Model.new)
    count = 0
    # a._new_item = {}
    a._new_item._name.on('changed') { count += 1 }
    expect(count).to eq(0)
    
    a._new_item._name = 'Testing'
    # expect(count).to eq(1)
  end
  
  describe "paths" do
    it "should store the path" do
      a = Model.new
      expect(a._test.path).to eq([:_test])
      a._test = {_name: 'Yes'}
      expect(a._test.path).to eq([:_test])
    
      a._items << {_name: 'Yes'}
      expect(a._items.path).to eq([:_items])
      expect(a._items[0].path).to eq([:_items, :[]])
    end
    
    it "should store the paths when assigned" do
      a = Model.new
      
      a._items = [{_name: 'Cool'}]
      
      expect(a._items.path).to eq([:_items])
      expect(a._items[0].path).to eq([:_items, :[]])
    end
    
    it "should handle nested paths" do
      a = Model.new
      
      a._items << {_name: 'Cool', _lists: [{_name: 'One'}, {_name: 'Two'}]}
      
      expect(a._items[0]._lists.path).to eq([:_items, :[], :_lists])
      expect(a._items[0]._lists[1].path).to eq([:_items, :[], :_lists, :[]])
    end
    
    it "should trigger added when added" do
      a = ReactiveValue.new(Model.new)
      count = 0
      b = a._items

      b.on('added') { count += 1 }
      expect(count).to eq(0)
      
      c = b.cur
      c << {_name: 'one'}

      # TODO: Without fetching this again, this fails.
      c = b.cur
      
      c << {_name: 'two'}
      
      expect(count).to eq(2)
    end
  end
  
  it "should trigger on false assign" do
    a = ReactiveValue.new(Model.new)
    
    count1 = 0
    count2 = 0
    
    b = a._complete
    c = a._complete
    b.on('changed') { count1 += 1 }
    c.on('changed') { count2 += 1 }
    expect(count1).to eq(0)
    
    b._complete = true
    expect(count1).to eq(1)
    expect(count2).to eq(1)

    b._complete = false
    expect(count1).to eq(2)
    expect(count2).to eq(2)
    
  end
  
  it "should set its self to be " do
    
  end
  
  
  describe "model paths" do
    before do
      @model = ReactiveValue.new(Model.new)      
    end
    
    it "should set the model path" do
      @model._object._name = 'Test'
      expect(@model._object.path.cur).to eq([:_object])
    end
    
    it "should set the model path for a sub array" do
      @model._items << {_name: 'Bob'}
      expect(@model._items.path.cur).to eq([:_items])
      expect(@model._items[0].path.cur).to eq([:_items, :[]])
    end
    
    it "should set the model path for sub sub arrays" do
      @model._lists << {_name: 'List 1', _items: []}
      expect(@model._lists[0]._items.path.cur).to eq([:_lists, :[], :_items])
    end
  end
  
  describe "persistors" do
    it "should setup a new instance of the persistor with self" do
      persistor = double('persistor')
      expect(persistor).to receive(:new)
      @model = Model.new(nil, persistor: persistor)
    end
  end
end