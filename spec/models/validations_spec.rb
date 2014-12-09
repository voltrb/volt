require 'spec_helper'

class TestModel < Volt::Model
  validate :count, numericality: { min: 5, max: 10 }
  validate :description, length: { message: 'needs to be longer', length: 50 }
  validate :email, email: true
  validate :name, length: 4
  validate :username, presence: true
end

describe Volt::Model do
  it 'should validate the name' do
    expect(TestModel.new.errors).to eq(
      count: ['must be a number'],
      description: ['needs to be longer'],
      email: ['must be an email address'],
      name: ['must be at least 4 characters'],
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
      [:count, :description, :email, :name, :username]
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
end
