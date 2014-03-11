require 'volt/extra_core/inflector'

describe Inflector do
  it "should pluralize correctly" do
    expect('car'.pluralize).to eq('cars')
    # expect('database'.pluralize).to eq('database')
  end
end