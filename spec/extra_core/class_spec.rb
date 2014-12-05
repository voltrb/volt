require 'spec_helper'
require 'volt/extra_core/array'

class TestClassAttributes
  class_attribute :some_data
end

class TestSubClassAttributes < TestClassAttributes
end

class TestSubClassAttributes2 < TestClassAttributes
end

describe "extra_core class addons" do
  it 'should provide class_attributes that can be inherited' do
    expect(TestClassAttributes.some_data).to eq(nil)

    TestClassAttributes.some_data = 5
    expect(TestClassAttributes.some_data).to eq(5)
    expect(TestSubClassAttributes.some_data).to eq(5)
    expect(TestSubClassAttributes2.some_data).to eq(5)

    TestSubClassAttributes.some_data = 10
    expect(TestClassAttributes.some_data).to eq(5)
    expect(TestSubClassAttributes.some_data).to eq(10)
    expect(TestSubClassAttributes2.some_data).to eq(5)

    TestSubClassAttributes2.some_data = 15
    expect(TestClassAttributes.some_data).to eq(5)
    expect(TestSubClassAttributes.some_data).to eq(10)
    expect(TestSubClassAttributes2.some_data).to eq(15)
  end
end