require 'spec_helper'
require 'volt/models'


class TestItem < Model
end

class Item < Model
end


describe Model do

  it "should allow _ methods to be used to store values without predefining them" do
    a = Model.new
    a._stash = 'yes'

    expect(a._stash).to eq('yes')
  end

  it "should update other values off the same model" do
    a = Model.new

    values = []
    -> { values << a._name }.watch!

    expect(values).to eq([nil])
    Computation.flush!

    a._name = 'Bob'

    Computation.flush!
    expect(values).to eq([nil, 'Bob'])
  end

  it "should say unregistered attributes are nil" do
    a = Model.new
    b = a._missing == nil
    expect(b).to eq(true)
  end

  it "should negate nil and false correctly" do
    a = Model.new
    expect((!a._missing)).to eq(true)

    a._mis1 = nil
    a._false1 = false

    expect(!a._mis1).to eq(true)
    expect(!a._false1).to eq(true)
  end

  it "should return a nil model for an underscore value that doesn't exist" do
    a = Model.new
    expect(a._something.attributes).to eq(nil)
  end


  it "should trigger changed once when a new value is assigned." do
    a = Model.new

    count = 0
    -> { a._blue ; count += 1 }.watch!
    expect(count).to eq(1)

    a._blue = 'one'
    Computation.flush!
    expect(count).to eq(2)

    a._blue = 'two'
    Computation.flush!
    expect(count).to eq(3)
  end

  it "should not trigger changed on other attributes" do
    a = Model.new

    blue_count = 0
    green_count = 0


    -> { a._blue ; blue_count += 1 }.watch!
    -> { a._green ; green_count += 1 }.watch!
    expect(blue_count).to eq(1)
    expect(green_count).to eq(1)

    a._green = 'one'
    Computation.flush!
    expect(blue_count).to eq(1)
    expect(green_count).to eq(2)

    a._blue = 'two'
    Computation.flush!
    expect(blue_count).to eq(2)
    expect(green_count).to eq(2)
  end

  it "should call change through arguments" do
    a = Model.new
    a._one = 1
    a._two = 2
    a._three = 3

    c = nil
    count = 0
    -> { c = a._one + a._two ; count += 1 }.watch!

    expect(count).to eq(1)

    a._two = 5
    Computation.flush!
    expect(count).to eq(2)

    a._one = 6
    Computation.flush!
    expect(count).to eq(3)

    a._three = 7
    Computation.flush!
    expect(count).to eq(3)
  end

  it 'should update through a normal array' do
    model = Model.new
    array = []
    array << model

    values = []

    -> { values << array[0]._prop }.watch!

    expect(values).to eq([nil])

    model._prop = 'one'
    Computation.flush!

    expect(values).to eq([nil, 'one'])

  end

  it "should trigger changed for any indicies after a deleted index" do
    model = Model.new

    model._items << {_name: 'One'}
    model._items << {_name: 'Two'}
    model._items << {_name: 'Three'}

    count = 0
    -> { model._items[2] ; count += 1 }.watch!
    expect(count).to eq(1)

    model._items.delete_at(1)
    Computation.flush!
    expect(count).to eq(2)
  end

  it "should change the size and length when an item gets added" do
    model = Model.new

    model._items << {_name: 'One'}
    size = model._items.size
    length = model._items.length

    count_size = 0
    count_length = 0
    -> { model._items.size ; count_size += 1 }.watch!
    -> { model._items.length ; count_length += 1 }.watch!
    expect(count_size).to eq(1)
    expect(count_length).to eq(1)

    model._items << {_name: 'Two'}
    Computation.flush!

    expect(count_size).to eq(2)
    expect(count_length).to eq(2)
  end

  it "should add doubly nested arrays" do
    model = Model.new

    model._items << {_name: 'Cool', _lists: []}
    model._items[0]._lists << {_name: 'worked'}
    expect(model._items[0]._lists[0]._name).to eq('worked')
  end

  it "should make pushed subarrays into ArrayModels" do
    model = Model.new

    model._items << {_name: 'Test', _lists: []}
    expect(model._items[0]._lists.class).to eq(ArrayModel)
  end

  it "should make assigned subarrays into ArrayModels" do
    model = Model.new

    model._item._name = 'Test'
    model._item._lists = []
    expect(model._item._lists.class).to eq(ArrayModel)
  end

  it "should call changed when a the reference to a submodel is assigned to another value" do
    a = Model.new

    count = 0
    -> { a._blue && a._blue.respond_to?(:_green) && a._blue._green ; count += 1 }.watch!
    expect(count).to eq(1)

    a._blue._green = 5
    Computation.flush!

    # TODO: Should equal 2
    expect(count).to eq(2)

    a._blue = 22
    Computation.flush!
    expect(count).to eq(3)

    a._blue = {_green: 50}
    expect(a._blue._green).to eq(50)
    Computation.flush!
    expect(count).to eq(4)
  end

  it "should trigger changed when a value is deleted" do
    a = Model.new

    count = 0
    -> { a._blue ; count += 1 }.watch!
    expect(count).to eq(1)

    a._blue = 1
    Computation.flush!
    expect(count).to eq(2)

    a.delete(:_blue)
    Computation.flush!
    expect(count).to eq(3)
  end

  it "should let you append nested hashes" do
    a = Model.new

    a._items << {_name: {_text: 'Name'}}

    expect(a._items[0]._name._text).to eq('Name')
  end


  it "should not call added too many times" do
    a = Model.new
    a._list << 1

    count = 0
    a._list.on('added') { count += 1 }
    expect(count).to eq(0)

    a._list << 2
    expect(count).to eq(1)
  end

  it "should propigate to different branches" do
    a = Model.new
    count = 0
    -> do
      count += 1
      a._new_item._name
    end.watch!
    expect(count).to eq(1)

    a._new_item._name = 'Testing'
    Computation.flush!
    expect(count).to eq(2)
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
      a = Model.new
      count = 0
      b = a._items

      b.on('added') { count += 1 }
      expect(count).to eq(0)

      b << {_name: 'one'}
      b << {_name: 'two'}

      expect(count).to eq(2)
    end
  end

  it "should trigger on false assign" do
    a = Model.new
    count = 0

    -> { count += 1 ; a._complete }.watch!

    expect(count).to eq(1)

    a._complete = true
    Computation.flush!
    expect(count).to eq(2)

    a._complete = false
    Computation.flush!
    expect(count).to eq(3)
  end

  it "should delete from an ArrayModel" do
    array = ArrayModel.new([])

    array << {_name: 'One'}
    array << {_name: 'Two'}
    array << {_name: 'Three'}

    expect(array.size).to eq(3)

    expect(array.index(array[0])).to eq(0)

    array.delete(array[0])
    expect(array.size).to eq(2)
    expect(array[0]._name).to eq('Two')
  end

  it "should compare true" do
    a = Model.new({_name: 'Cool'})
    expect(a == a).to eq(true)
  end

  it "should do index" do
    a = [{name: 'One'}, {name: 'Two'}, {name: 'Three'}]
    expect(a.index(a[1])).to eq(1)
  end

  it "should convert to a hash, and unwrap all of the way down" do
    a = Model.new
    a._items << {_name: 'Test1', _other: {_time: 'Now'}}
    a._items << {_name: 'Test2', _other: {_time: 'Later'}}

    item1 = a._items[0].to_h
    expect(item1[:_name]).to eq('Test1')
    expect(item1[:_other][:_time]).to eq('Now')

    all_items = a._items.to_a

    a = [
      {:_name => "Test1", :_other => {:_time => "Now"}},
      {:_name => "Test2", :_other => {:_time => "Later"}}
    ]
    expect(all_items).to eq(a)
  end


  describe "model paths" do
    before do
      @model = Model.new
    end

    it "should set the model path" do
      @model._object._name = 'Test'
      expect(@model._object.path).to eq([:_object])
    end

    it "should set the model path for a sub array" do
      @model._items << {_name: 'Bob'}
      expect(@model._items.path).to eq([:_items])
      expect(@model._items[0].path).to eq([:_items, :[]])
    end

    it "should set the model path for sub sub arrays" do
      @model._lists << {_name: 'List 1', _items: []}
      expect(@model._lists[0]._items.path).to eq([:_lists, :[], :_items])
    end

    it "should update the path when added from a model instance to a collection" do
      test_item = TestItem.new

      @model._items << test_item
      expect(@model._items[0].path).to eq([:_items, :[]])
    end
  end

  describe "persistors" do
    it "should setup a new instance of the persistor with self" do
      persistor = double('persistor')
      expect(persistor).to receive(:new)
      @model = Model.new(nil, persistor: persistor)
    end
  end

  if RUBY_PLATFORM != 'opal'
    describe "class loading" do
      it 'should load classes for models' do
        $page = Page.new
        $page.add_model('Item')

        @model = Model.new

        # Should return a buffer of the right type
        expect(@model._items.buffer.class).to eq(Item)

        # Should insert as the right type
        @model._items << {_name: 'Item 1'}
        expect(@model._items[0].class).to eq(Item)
      end
    end
  end
end
