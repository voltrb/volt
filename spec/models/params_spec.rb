require 'volt/models'

describe Persistors::Params do
  it "should stay as params classes when used" do
    a = Model.new({}, persistor: Persistors::Params)
    expect(a._test.class).to eq(Model)
    # 
    # expect(a._test._cool.class).to eq(Params)
    # 
    # a._items << {_name: 'Test'}
    # 
    # expect(a._items.class).to eq(ParamsArray)
    # expect(a._items[0].class).to eq(Params)
    # expect(a._items[0]._name.class).to eq(String)
  end
end
