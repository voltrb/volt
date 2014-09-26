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


end