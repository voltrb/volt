require 'volt/models'

describe ReactiveBlock do
  it "should call cur through the reactive count to the number" do
    model = ReactiveValue.new(Model.new)

    model._items << {_name: 'ok'}

    count = model._items.count {|m| m._name == 'ok' }

    expect(count.cur).to eq(1)
  end
end