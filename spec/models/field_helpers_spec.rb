require 'spec_helper'
require 'volt/models'

class ExampleModelWithField < Volt::Model
  field :name
  field :value, Numeric
end

describe 'field helpers' do
  it 'should allow a user to setup a field that can be written to and read' do
    model = ExampleModelWithField.new

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
      ExampleModelWithField.field :awesome, Array
    end.to raise_error(FieldHelpers::InvalidFieldClass)
  end
end
