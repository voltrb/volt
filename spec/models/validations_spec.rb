require 'spec_helper'

describe Volt::Model do
  let(:model) { test_model_class.new }

  let(:test_model_class) do
    Class.new(Volt::Model) do
      validate :count, numericality: { min: 5, max: 10 }
      validate :description, length: { message: 'needs to be longer',
                                       length: 50 }
      validate :email, email: true
      validate :name, length: 4
      validate :phone_number, phone_number: true
      validate :username, presence: true
    end
  end

  it 'should return errors for all failed validations' do
    expect(model.errors).to eq(
      count: ['must be a number'],
      description: ['needs to be longer'],
      email: ['must be an email address'],
      name: ['must be at least 4 characters'],
      phone_number: ['must be a phone number with area or country code'],
      username: ['must be specified']
    )
  end

  it 'should show all fields in marked errors once saved' do
    model.save!

    expect(model.marked_errors.keys).to eq(
      [:count, :description, :email, :name, :phone_number, :username]
    )
  end

  describe 'builtin validations' do
    shared_examples_for 'a built in validation' do |field, message|
      specify do
        expect { model.mark_field! field }
          .to change { model.marked_errors }
          .from({}).to({ field => [message ] })
      end
    end

    describe 'numericality' do
      message = 'must be a number'
      it_should_behave_like 'a built in validation', :count, message
    end

    describe 'length' do
      message = 'needs to be longer'
      it_should_behave_like 'a built in validation', :description, message
    end

    describe 'email' do
      message = 'must be an email address'
      it_should_behave_like 'a built in validation', :email, message
    end

    describe 'name' do
      message = 'must be at least 4 characters'
      it_should_behave_like 'a built in validation', :name, message
    end

    describe 'phone_number' do
      message = 'must be a phone number with area or country code'
      it_should_behave_like 'a built in validation', :phone_number, message
    end

    describe 'presence' do
      message = 'must be specified'
      it_should_behave_like 'a built in validation', :username, message
    end
  end

  describe 'validators with multiple criteria' do
    let(:regex_message) { 'regex failed' }
    let(:proc_message) { 'proc failed' }

    let(:test_model_class) do
      Class.new(Volt::Model) do
        validate :special_field, format: [
          { with: /regex/, message: 'regex failed' },
          { with: ->(x) {x == false}, message: 'proc failed' }
        ]
      end
    end

    context 'when multiple fail' do
      before { model._special_field = 'nope' }

      it 'returns an array of errors' do
        expect(model.errors).to eq({
          special_field: [ regex_message, proc_message ]
        })
      end
    end

    context 'when one fails' do
      before { model._special_field = 'regex' }

      it 'returns an array with a single error' do
        expect(model.errors).to eq({ special_field: [ proc_message ] })
      end
    end
  end
end
