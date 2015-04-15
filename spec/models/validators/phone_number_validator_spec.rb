require 'spec_helper'
require 'models/validators/shared_examples_for_validators'

describe Volt::PhoneNumberValidator do
  subject { described_class.new(*init_params) }
  let(:init_params) { [model, field_name] }

  let(:model) { Volt::Model.new phone_number: phone_number }
  let(:field_name) { :phone_number }
  let(:options) { true }

  let(:phone_number) { field_content }
  let(:field_contet) { valid_us_number }
  let(:valid_us_number) { '(123)-123-1234' }
  let(:valid_intl_number) { '+12 123 123 1234' }
  let(:invalid_number) { '1234-123-123456' }

  let(:validate) { described_class.validate(*params) }
  let(:params) { [model, field_name, options] }
  let(:message) { 'must be a phone number with area or country code' }

  it_behaves_like 'a format validator'

  before do
    allow(described_class).to receive(:new).and_return subject
  end

  context 'when the phone number is a valid US number' do
    let(:phone_number) { valid_us_number }

    specify { expect(validate).to eq({}) }

    context 'and when no override criteria is provided' do
      before { validate }

      it 'should have no errors' do
        expect(subject.errors).to eq({})
      end

      specify { expect(subject).to be_valid }
    end
  end

  context 'when the model has an invalid phone number' do
    let(:phone_number) { invalid_number }

    context 'and when no override criteria is provided' do
      before { validate }

      it 'returns an array of errors for phone number' do
        expect(subject.errors).to eq field_name => [message]
      end
    end
  end

  context 'when the phone number is a valid international number' do
    let(:phone_number) { valid_intl_number }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when the phone number uses dashes' do
    let(:phone_number) { '123-123-1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when the phone number uses periods' do
    let(:phone_number) { '123.123.1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when the phone number uses spaces' do
    let(:phone_number) { '123 123 1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when the phone number uses parentheses and a space' do
    let(:phone_number) { '(123) 123.1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when an international number uses a plus' do
    let(:phone_number) { '+12 123 123 1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when an international number does not use a plus' do
    let(:phone_number) { '12 123 123 1234' }

    specify { expect(subject.valid?).to eq true }
  end

  context 'when an international number is from the UK' do
    let(:phone_number) { '+12 123 1234 1234' }

    specify { expect(subject.valid?).to eq true }
  end
end