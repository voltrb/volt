require 'spec_helper'

describe "Volt::Dirty" do
  let(:model) do
    model = Volt::Model.new

    # Run changed on the model will revert changes after each sync
    allow(model).to receive(:run_changed)

    model
  end

  it 'should track changed attributes' do
    model._name = 'Bob'
    expect(model.name_was).to eq(nil)

    model._name = 'Jimmy'
    expect(model.name_was).to eq(nil)
    expect(model.name_changes).to eq([nil, 'Bob'])

    model._name = 'Martin'
    expect(model.name_was).to eq(nil)
    expect(model.name_changes).to eq([nil, 'Bob', 'Jimmy'])

    model._name = nil
    expect(model.name_was).to eq(nil)
    expect(model.name_changes).to eq([nil, 'Bob', 'Jimmy', 'Martin'])

    model._name = 'Ryan'
    expect(model.name_was).to eq(nil)
    expect(model.name_changes).to eq([nil, 'Bob', 'Jimmy', 'Martin', nil])

    expect(model.changed_attributes).to eq({:name=>[nil, "Bob", "Jimmy", "Martin", nil]})
  end

  it 'should say models are changed' do
    expect(model.changed?(:name)).to eq(false)
    model._name = 'Bob'

    expect(model.changed?(:name)).to eq(true)
    model._name = 'Jimmy'

    expect(model.changed?(:name)).to eq(true)

    model.clear_tracked_changes!

    expect(model.changed?(:name)).to eq(false)
  end

  it 'should reset changes' do
    expect(model.changed?(:name)).to eq(false)
    model._name = 'Bob'
    expect(model.changed?(:name)).to eq(true)
    model._name = 'Jimmy'
    expect(model.changed?(:name)).to eq(true)

    expect(model.name_was).to eq(nil)
    expect(model.name_changes).to eq([nil, 'Bob'])

    model.clear_tracked_changes!

    expect(model.name_was).to eq(nil)
  end

  it 'should not track when assigning the same value' do
    expect(model.changed?(:name)).to eq(false)
    model._name = nil
    expect(model.changed?(:name)).to eq(false)

    model._name = 'bob'
    expect(model.changed?(:name)).to eq(true)
    expect(model.name_changes).to eq([nil])

    model._name = 'bob'
    expect(model.name_changes).to eq([nil])
  end

  it 'should revert changes' do
    expect(model.attributes).to eq({})
    model.attributes = {first: 'Bob', last: 'Smith'}
    expect(model.attributes).to eq({first: 'Bob', last: 'Smith'})

    model.revert_changes!
    expect(model.attributes).to eq({first: nil, last: nil})
  end

  it 'should revert changes after a clear_tracked_changed!' do
    expect(model.attributes).to eq({})
    model.attributes = {first: 'Bob', last: 'Smith'}
    expect(model.attributes).to eq({first: 'Bob', last: 'Smith'})

    model.clear_tracked_changes!
    expect(model.changed_attributes).to eq({})

    model._first = 'Jimmy'
    model._last = 'Dean'
    expect(model.attributes).to eq({first: 'Jimmy', last: 'Dean'})

    model.revert_changes!
    expect(model.attributes).to eq({first: 'Bob', last: 'Smith'})
  end
end