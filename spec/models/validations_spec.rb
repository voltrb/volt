require 'volt/models'

class TestModel < Model
  validate :_name, length: 4
end

describe Model do
  it "should validate the name" do
    expect(TestModel.new.errors).to eq({:_name => ["must be at least 4 chars"]})
  end
end