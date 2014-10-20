require 'spec_helper'
require 'volt/models'

describe Volt::Persistors::Params do
  it 'should stay as params classes when used' do
    a = Volt::Model.new({}, persistor: Volt::Persistors::Params)
    expect(a._test.class).to eq(Volt::Model)

    expect(a._test._cool.persistor.class).to eq(Volt::Persistors::Params)

    a._items << { name: 'Test' }

    expect(a._items.persistor.class).to eq(Volt::Persistors::Params)
    expect(a._items[0].persistor.class).to eq(Volt::Persistors::Params)
    expect(a._items[0]._name.class).to eq(String)
  end
end
