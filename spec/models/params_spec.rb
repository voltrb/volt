require 'volt/models'

describe Params do
  it "should stay as params classes when used" do
    a = Params.new
    expect(a._test.class).to eq(Params)
    
    expect(a._test._cool.class).to eq(Params)
    
    a._items << {_name: 'Test'}
    
    expect(a._items.class).to eq(ParamsArray)
    expect(a._items[0].class).to eq(Params)
    expect(a._items[0]._name.class).to eq(String)
  end
end
