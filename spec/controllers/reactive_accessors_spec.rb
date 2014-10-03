require 'spec_helper'
require 'volt/reactive/reactive_accessors'

class TestReactiveAccessors
  include ReactiveAccessors

  reactive_accessor :_name
end

describe ReactiveAccessors do
  it "should assign a reactive value" do
    inst = TestReactiveAccessors.new

    inst._name = 'Ryan'
    expect(inst._name).to eq('Ryan')
  end

  it "should start nil" do
    inst = TestReactiveAccessors.new

    expect(inst._name).to eq(nil)
  end

  it 'should trigger changed when assigning a new value' do
    inst = TestReactiveAccessors.new
    values = []

    -> { values << inst._name }.watch!

    expect(values).to eq([nil])

    inst._name = 'Ryan'
    Computation.flush!
    expect(values).to eq([nil,'Ryan'])

    inst._name = 'Stout'
    Computation.flush!
    expect(values).to eq([nil,'Ryan','Stout'])
  end
end