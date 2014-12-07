require 'spec_helper'

describe Volt::Dirty do
  it 'should track changed attributes' do
    model = Volt::Model.new

    model._name = 'Bob'
    model.previous
  end
end