require 'spec_helper'
require 'volt/models'

class ExampleModelWithField < Volt::Model
  field :name
  field :value, Numeric
end

class ExampleModelWithField2 < ExampleModelWithField
end

describe 'field helpers' do
  let(:model) { ExampleModelWithField.new }
  it 'should allow a user to setup a field that can be written to and read' do

    expect(model.name).to eq(nil)
    model.name = 'jimmy'
    expect(model.name).to eq('jimmy')

    expect(model.value).to eq(nil)
    model.value = '20.5'

    # Should be cast to float
    expect(model.value).to eq(20.5)
  end

  it 'should raise an error when an invalid cast type is provided' do
    expect do
      ExampleModelWithField2.field :awesome, Range
    end.to raise_error(Volt::FieldHelpers::InvalidFieldClass)
  end

  it 'should convert numeric strings to Fixnum when Fixnum is specified as a type restriction' do
    model.value = '22'
    expect(model.value).to eq(22)
  end

  it 'should not convert non-numeric strings (and have a validation error)' do
    # use a buffer, so we can put the model into an invalid state
    buf = model.buffer
    buf.value = 'cats'
    expect(buf.value).to eq('cats')

    fail_called = false
    buf.validate!.fail do |error|
      fail_called = true
      expect(error).to eq({'value' => ['must be a number']})
    end

    expect(fail_called).to eq(true)
  end

  it 'should track the fields on the model class' do
    expect(ExampleModelWithField.fields).to eq({:name=>[nil, {}], :value=>[[Numeric, NilClass], {}]})
  end
end
