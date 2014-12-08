require 'spec_helper'

describe "Volt::Dirty" do
  let(:model) { Volt::Model.new }

  it 'should track changed attributes' do
    model._name = 'Bob'
    expect(model.name_was).to eq(nil)

    model._name = 'Jimmy'
    expect(model.name_was).to eq('Bob')
    expect(model.name_changes).to eq(['Bob'])

    model._name = 'Martin'
    expect(model.name_was).to eq('Bob')
    expect(model.name_changes).to eq(['Bob', 'Jimmy'])

    model._name = nil
    expect(model.name_was).to eq('Bob')
    expect(model.name_changes).to eq(['Bob', 'Jimmy', 'Martin'])

    model._name = 'Ryan'
    expect(model.name_was).to eq('Bob')
    expect(model.name_changes).to eq(['Bob', 'Jimmy', 'Martin', nil])

    expect(model.changed_attributes).to eq({:name=>["Bob", "Jimmy", "Martin", nil]})
  end

  it 'should say models are changed' do
    expect(model.changed?(:name)).to eq(false)
    model._name = 'Bob'

    expect(model.changed?(:name)).to eq(false)
    model._name = 'Jimmy'

    expect(model.changed?(:name)).to eq(true)

    model.reset_changes

    expect(model.changed?(:name)).to eq(false)
  end

  it 'should reset changes' do
    model._name = 'Bob'
    model._name = 'Jimmy'

    expect(model.name_was).to eq('Bob')

    model.reset_changes

    expect(model.name_was).to eq(nil)
  end
end