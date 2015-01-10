require 'spec_helper'

describe Volt::PhoneNumberValidator do
  subject { Volt::PhoneNumberValidator.new(*params) }
  let(:params) { [model, field_name, options] }

  let(:model) { Volt::Model.new phone_number: phone_number }
  let(:field_name) { :phone_number }
  let(:options) { true }

  let(:valid_us_number) { '(123)-123-1234' }
  let(:valid_intl_number) { '+12 123 123 1234' }
  let(:invalid_number) { '1234-123-123456' }
  let(:phone_number) { valid_us_number }

  describe '.validate' do
    let(:result) { described_class.validate(*params.dup.insert(1, nil)) }

    before do
      allow(described_class).to receive(:new).and_return subject
      allow(subject).to receive(:errors).and_call_original

      result
    end

    it 'initializes a phone number validator with the provided arguments' do
      expect(described_class).to have_received(:new).with(*params)
    end

    it 'calls errors on the phone number validator' do
      expect(subject).to have_received :errors
    end

    it 'returns the result of calling errors on the validator' do
      expect(subject.errors).to eq result
    end
  end

  describe '#valid?' do
    context 'when using the default regex' do
      let(:options) { true }

      context 'when the phone number is a valid US number' do
        let(:phone_number) { valid_us_number }

        specify { expect(subject.valid?).to eq true }
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

    context 'when using a custom regex' do
      let(:options) { { with: /\d{10}/ } }

      context 'and the phone number qualifies' do
        let(:phone_number) { '1231231234' }

        specify { expect(subject.valid?).to eq true }
      end

      context 'and the phone number does not qualify' do
        let(:phone_number) { '123-123-1234' }

        specify { expect(subject.valid?).to eq false }
      end
    end
  end

  describe '#errors' do
    context 'when the model has a valid phone number' do
      let(:phone_number) { valid_us_number }

      it 'returns an empty error hash' do
        expect(subject.errors).to eq({})
      end
    end

    context 'when the model has an invalid phone number' do
      let(:phone_number) { invalid_number }

      it 'returns an array of errors for phone number' do
        expect(subject.errors).to eq(
          phone_number: ['must be a phone number with area or country code'])
      end
    end

    context 'when provided a custom error message' do
      let(:options) { { message: custom_message } }
      let(:custom_message) { 'this is a custom message' }

      context 'and the phone number is invalid' do
        let(:phone_number) { invalid_number }

        it 'returns errors with the custom message' do
          expect(subject.errors).to eq(phone_number: [custom_message])
        end
      end
    end
  end
end
