require 'spec_helper'
require 'volt/extra_core/inflector'

describe Volt::Inflector do
  it 'should pluralize correctly' do
    expect('car'.pluralize).to eq('cars')
    # expect('database'.pluralize).to eq('database')
  end

  it 'should singularize correctly' do
    expect('cars'.singularize).to eq('car')
  end
end
