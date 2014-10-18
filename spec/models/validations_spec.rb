require 'volt/models'

class TestModel < Volt::Model
  validate :_name, length: 4
  validate :_description, length: {message: 'needs to be longer', length: 50}
  validate :_username, presence: true
end


describe Volt::Model do
  it "should validate the name" do
    expect(TestModel.new.errors).to eq(
      {
        :_name => ["must be at least 4 characters"],
        :_description => ["needs to be longer"],
        :_username => ["must be specified"]
      }
    )
  end

  it "should show marked validations once they are marked" do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.mark_field!(:_name)

    expect(model.marked_errors).to eq(
      {
        :_name => ["must be at least 4 characters"]
      }
    )
  end

  it "should show all fields in marked errors once saved" do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.save!

    expect(model.marked_errors.keys).to eq([:_name, :_description, :_username])
  end

  describe "length" do
    it "should allow custom errors on length" do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:_description)

      expect(model.marked_errors).to eq(
        {
          :_description => ["needs to be longer"]
        }
      )
    end
  end

  describe "presence" do
    it "should validate presence" do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:_username)

      expect(model.marked_errors).to eq(
        {
          :_username => ["must be specified"]
        }
      )
    end
  end
end
