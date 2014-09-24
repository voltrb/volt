require 'spec_helper'
require 'volt/reactive/reactive_array'

describe ReactiveArray do
  it 'should track dependencies for cells' do
    a = ReactiveArray.new

    count = 0
    values = []
    -> { values << a[0] ; count += 1 }.bind!

    a[0] = 5

    Dependency.flush!

    a[0] = 10
    expect(count).to eq(2)
    expect(values).to eq([nil, 5])

    Dependency.flush!
    expect(count).to eq(3)
    expect(values).to eq([nil, 5, 10])
  end
end