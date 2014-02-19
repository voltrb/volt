require 'volt/models'

describe Persistors::Params do
  it "should stay as params classes when used" do
    a = Model.new({}, persistor: Persistors::Params)
    expect(a._test.class).to eq(Model)

    expect(a._test._cool.persistor.class).to eq(Persistors::Params)

    a._items << {_name: 'Test'}

    expect(a._items.persistor.class).to eq(Persistors::Params)
    expect(a._items[0].persistor.class).to eq(Persistors::Params)
    expect(a._items[0]._name.class).to eq(String)
  end
end
