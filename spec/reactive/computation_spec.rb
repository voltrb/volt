require 'spec_helper'

describe Volt::Computation do
  it 'should trigger again when a dependent changes' do
    a = Volt::ReactiveHash.new

    values = []

    -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])

    a[0] = 'two'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one', 'two'])
  end

  it 'should not trigger after the computation is stopped' do
    a = Volt::ReactiveHash.new

    values = []
    computation = -> { values << a[0] }.watch!

    expect(values).to eq([nil])

    a[0] = 'one'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])

    computation.stop

    a[0] = 'two'
    Volt::Computation.flush!
    expect(values).to eq([nil, 'one'])
  end

  it 'should support nested watches' do
    a = Volt::ReactiveHash.new

    values = []
    -> do
      values << a[0]

      -> do
        values << a[1]
      end.watch!
    end.watch!

    expect(values).to eq([nil, nil])

    a[1] = 'inner'
    Volt::Computation.flush!
    expect(values).to eq([nil, nil, 'inner'])

    a[0] = 'outer'
    Volt::Computation.flush!
    expect(values).to eq([nil, nil, 'inner', 'outer', 'inner'])
  end
end
