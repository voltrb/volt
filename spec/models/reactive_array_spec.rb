require 'volt/models'

describe ReactiveArray do
  it "should trigger a change event on any ReactiveValues derived from items in the array" do
    model = ReactiveValue.new(Model.new)

    model._my_ary = [1,2,3]

    array_one_item = model._my_ary[4]

    @changed = false
    array_one_item.on('changed') { @changed = true }
    expect(@changed).to eq(false)

    model._my_ary.insert(0,1,2)

    expect(@changed).to eq(true)
  end

  it "should trigger changed from an insert in all places after the index" do
    model = ReactiveValue.new(Model.new)
    model._my_ary = [1,2,3]

    count1 = 0
    count2 = 0
    model._my_ary[1].on('changed') { count1 += 1 }
    model._my_ary[3].on('changed') { count2 += 1 }
    expect(count1).to eq(0)
    expect(count2).to eq(0)

    model._my_ary.insert(1, 10)
    expect(count1).to eq(1)
    expect(count2).to eq(1)

    expect(model._my_ary.cur).to eq([1,10,2,3])
  end

  it "should pass the index the item was inserted at" do
    model = ReactiveValue.new(Model.new)
    model._my_ary = [1,2,3]

    model._my_ary.on('added') do |_, index|
      expect(index).to eq(2)
    end

    model._my_ary.insert(2, 20)
  end

  it "should pass the index the item was inserted at with multiple inserted objects" do
    model = ReactiveValue.new(Model.new)
    model._my_ary = [1,2,3]

    received = []
    model._my_ary.on('added') do |_, index|
      received << index
    end

    model._my_ary.insert(2, 20, 30)

    expect(received).to eq([2, 3])
  end

  it "should trigger changed on methods of an array model that involve just one cell" do
    model = ReactiveValue.new(ReactiveArray.new)

    model << 1
    model << 2
    model << 3

    max = model.max
    expect(max.cur).to eq(3)

    count = 0
    max.on('changed') { count += 1 }
    expect(count).to eq(0)

    model[0] = 10

    expect(count).to eq(1)
    expect(max.cur).to eq(10)
  end

  it "should not trigger changed events on cells that are not being updated" do
    model = ReactiveValue.new(ArrayModel.new([]))

    model << 1
    model << 2
    model << 3

    index_0_count = 0
    last_count = 0
    sum_count = 0
    model[0].on('changed') { index_0_count += 1 }
    model.last.on('changed') { last_count += 1 }
    model.sum.on('changed') { sum_count += 1 }
    model[1] = 20

    expect(index_0_count).to eq(0)
    expect(sum_count).to eq(1)
    expect(last_count).to eq(0)

    expect(model[0].cur).to eq(1)
    expect(model[1].cur).to eq(20)
    expect(model[2].cur).to eq(3)
    expect(model.last.cur).to eq(3)
    expect(model.sum.cur).to eq(24)

    model[2] = 100
    expect(last_count).to eq(1)
  end

  it "should trigger added when an element is added" do
    a = ReactiveValue.new(Model.new)
    count = 0
    a._items.on('added') { count += 1 }
    expect(count).to eq(0)

    a._items << 1
    expect(count).to eq(1)
  end

  it "should trigger updates when appending" do
    [:size, :length, :count, :last].each do |attribute|
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      val = a.send(attribute)
      old_value = val.cur
      val.on('changed') { count += 1 }
      expect(count).to eq(0)

      added_count = 0
      a.on('added') { added_count += 1 }
      expect(added_count).to eq(0)

      a << 4

      expect(val.cur).to eq(old_value + 1)
      expect(count).to eq(1)

      expect(added_count).to eq(1)
    end
  end

  describe "real world type specs" do
    it "should let you add in another array" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      pos_4 = a[4]
      expect(pos_4.cur).to eq(nil)
      pos_4_changed = 0
      pos_4.on('changed') { pos_4_changed += 1 }

      count = 0
      a.on('added') { count += 1 }

      a += [4,5,6]
      expect(a.cur).to eq([1,2,3,4,5,6])
      # TODO: Failing?
      # expect(pos_4_changed).to eq(1)

      # expect(count).to eq(3)
    end

    it "should trigger changes when an index that is Reactive changes" do
      index = ReactiveValue.new(0)
      model = ReactiveValue.new(Model.new)
      model._array << 1
      model._array << 2
      model._array << 3
      b = model._array[index]

      direct_count = 0
      b.on('changed') { direct_count += 1 }
      expect(direct_count).to eq(0)

      model._current_array = b

      count = 0

      model._current_array.on('changed') { count += 1 }
      expect(count).to eq(0)

      index.cur = 1
      expect(count).to eq(1)
      expect(direct_count).to eq(1)
    end

    it "should trigger changes when cell data changes when using ReactiveValue's as indicies" do
      index = ReactiveValue.new(0)
      index2 = ReactiveValue.new(0)
      model = ReactiveValue.new(Model.new)
      model._array << 1
      model._array << 2
      model._array << 3

      zero_cell = model._array[index]
      zero_cell2 = model._array[index2]

      count = 0
      count2 = 0
      zero_cell.on('changed') { count += 1 }
      zero_cell2.on('changed') { count2 += 1 }

      zero_cell.cur = 3

      expect(count).to eq(1)
      expect(count2).to eq(1)
    end


    it "should call added on an array within an array" do
      a = ReactiveValue.new(Model.new)
      index = ReactiveValue.new(0)
      count = 0
      a._items << ArrayModel.new([])

      a._items[0].on('added') { count += 1 }
      expect(count).to eq(0)

      a._items[0] << 1
      expect(count).to eq(1)

    end

    # TODO: Needs to be fixed
    # it "should call added through an index from one array to a sub array" do
    #   model = ReactiveValue.new(Model.new)
    #   index = ReactiveValue.new(nil)
    #
    #   count = 0
    #   model._current_todo._todos.on('added') { count += 1 }
    #   expect(count).to eq(0)
    #
    #   model._todo_lists << Model.new(_name: 'One', _todos: [])
    #   model._todo_lists << Model.new(_name: 'Two', _todos: [])
    #
    #   model._current_todo = model._todo_lists[0]
    #
    #   model._current_todo._todos << "Svoltle todo"
    #   expect(count).to eq(1)
    # end

    it "should trigger changed when an item is deleted" do
      model = ReactiveValue.new(Model.new)
      model._items = [1,2,3]

      cur = model._current = model._items[0]

      count = 0
      # model._items[0].on('changed') { count += 1}
      model._current.on('changed') { count += 1 }
      expect(count).to eq(0)

      model._items.delete_at(0)

      expect(count).to eq(1)
    end

    it "should not trigger changed on the array when an element is added" do
      a = ReactiveValue.new(Model.new)
      a._items = []

      count = 0
      a._items.on('changed') { count += 1}
      expect(count).to eq(0)

      a._items << 1
      expect(count).to eq(0)
    end

    it "should trigger changed for a Reactive index and a non-reactive index with the same value" do
      a = ReactiveValue.new(Model.new)
      index = ReactiveValue.new(0)
      a._items << 0
      a._items << 1

      count = 0
      a._items[0].on('changed') { count += 1 }
      expect(count).to eq(0)

      a._items[index] = 5
      expect(count).to eq(1)

      # Reversed
      count2 = 0
      a._items[index].on('changed') { count2 += 1 }
      expect(count2).to eq(0)

      index.cur = 1

      # Double update since one is bound to a Integer and one to a ReactiveValue
      # TODO: Any way to combine these
      expect(count2).to eq(2)

      a._items[1] = 2
      expect(count2).to eq(3)

      # a._items[index] = 10


    end

    it "should trigger changed with a negative index assignment" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count_0 = 0
      count_1 = 0

      a[0].on('changed') { count_0 += 1 }
      a[1].on('changed') { count_1 += 1 }

      a[-2] = 50

      expect(count_0).to eq(0)
      expect(count_1).to eq(1)
    end

    it "should not trigger on other indicies" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      a[0].on('changed') { count += 1 }
      expect(count).to eq(0)

      a[1] = 5
      expect(count).to eq(0)
    end
  end

  # describe "concat, diff" do
  #   it "should concat two arrays and trigger added/removed through" do
  #     a = ReactiveValue.new(ReactiveArray.new([1,2,3]))
  #     b = ReactiveValue.new(ReactiveArray.new([1,2,3]))
  #
  #     c = a + b
  #
  #     count = 0
  #     # c.on('added') { count += 1 }
  #     c.on('changed') { count += 1 }
  #     expect(count).to eq(0)
  #
  #     b << 4
  #
  #     expect(count).to eq(1)
  #   end
  # end

  describe "array methods" do
    it "should handle compact with events" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,nil,3]))

      count = 0
      last_position = nil
      compact = a.compact
      compact.on('changed') { count += 1 }
      expect(count).to eq(0)

      a << 4

      expect(count).to eq(1)
    end
  end
end
