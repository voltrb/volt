require 'spec_helper'

class TestModel < Volt::Model
  validate :count, numericality: { min: 5, max: 10 }
  validate :description, length: { message: 'needs to be longer', length: 50 }
  validate :email, email: true
  validate :name, length: 4
  validate :phone_number, phone_number: true
  validate :username, presence: true
end

describe Volt::Model do
  it 'should validate the name' do
    expect(TestModel.new.errors).to eq(
      count: ['must be a number'],
      description: ['needs to be longer'],
      email: ['must be an email address'],
      name: ['must be at least 4 characters'],
      phone_number: ['must be a phone number with area or country code'],
      username: ['must be specified']
    )
  end

  it 'should show marked validations once they are marked' do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.mark_field!(:name)

    expect(model.marked_errors).to eq(
      name: ['must be at least 4 characters']
    )
  end

  it 'should show all fields in marked errors once saved' do
    model = TestModel.new

    expect(model.marked_errors).to eq({})

    model.save!

    expect(model.marked_errors.keys).to eq(
      [:count, :description, :email, :name, :phone_number, :username]
    )
  end

  describe 'length' do
    it 'should allow custom errors on length' do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:description)

      expect(model.marked_errors).to eq(
        description: ['needs to be longer']
      )
    end
  end

  describe 'presence' do
    it 'should validate presence' do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:username)

      expect(model.marked_errors).to eq(
        username: ['must be specified']
      )
    end
  end

  describe 'numericality' do
    it 'should validate numericality' do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:count)

      expect(model.marked_errors).to eq(
        count: ['must be a number']
      )
    end

    it 'should fail on non-numbers' do
      model = TestModel.new

      model._count = 'not a number'
      expect(model.errors[:count]).to eq(['must be a number'])
    end
  end

  describe 'email' do
    it 'should validate email' do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:email)

      expect(model.marked_errors).to eq(
        email: ['must be an email address']
      )
    end
  end

  describe 'phone_number' do
    it 'should validate phone number' do
      model = TestModel.new

      expect(model.marked_errors).to eq({})

      model.mark_field!(:phone_number)

      expect(model.marked_errors).to eq(
        phone_number: ['must be a phone number with area or country code']
      )
    end
  end

  it 'should report if errors have happened in changed attributes' do
    model = TestModel.new

    # Prevent run_changed so it doesn't revert on failed values
    allow(model).to receive(:run_changed)

    expect(model.error_in_changed_attributes?).to eq(false)

    model._not_validated_attr = 'yes'
    expect(model.error_in_changed_attributes?).to eq(false)

    model._name = '5' # fail, too short
    expect(model.changed?(:name)).to eq(true)
    expect(model.error_in_changed_attributes?).to eq(true)

    model._name = 'Jimmy'
    expect(model.error_in_changed_attributes?).to eq(false)
  end

  it 'should revert changes which fail a validation' do
    model = TestModel.new

    model._name = 'bob' # fails too short validation
    expect(model._name).to eq(nil)

    model._name = 'Jimmy' # long enough, passes
    expect(model._name).to eq('Jimmy')
  end
end
