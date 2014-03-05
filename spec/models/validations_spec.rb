require 'volt/models'

class TestModel < Model
  validate :_name, length: 4
end

describe Model do
  it "should validate the name" do
    expect(TestModel.new.errors).to eq({:_name => ["must be at least 4 chars"]})
  end

  it "should show marked validations once they are marked" do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.mark_field!(:_name)

    expect(model.marked_errors).to eq({:_name=>["must be at least 4 chars"]})
  end

  it "should show all fields in marked errors once saved" do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.save!

    expect(model.marked_errors).to eq({:_name=>["must be at least 4 chars"]})
  end
end