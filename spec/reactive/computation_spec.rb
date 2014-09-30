require 'spec_helper'

describe Computation do
  it 'should trigger again when a dependent changes' do
    a = ReactiveHash.new

    values = []

    -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Dependency.flush!
    expect(values).to eq([nil, 'one'])

    a[0] = 'two'
    Dependency.flush!
    expect(values).to eq([nil, 'one', 'two'])
  end

  it 'should not trigger after the computation is stopped' do
    a = ReactiveHash.new

    values = []
    computation = -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Dependency.flush!
    expect(values).to eq([nil, 'one'])

    computation.stop

    a[0] = 'two'
    Dependency.flush!
    expect(values).to eq([nil, 'one'])
  end
end
