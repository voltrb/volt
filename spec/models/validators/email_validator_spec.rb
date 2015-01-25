require 'spec_helper'

describe Volt::EmailValidator do
  subject { Volt::EmailValidator.new(*params) }
  let(:params) { [model, field_name, options] }

  let(:model) { Volt::Model.new email: email }
  let(:field_name) { :email }
  let(:options) { true }

  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'test@example-com' }
  let(:email) { valid_email }

  describe '.validate' do
    let(:result) { described_class.validate(*params.dup.insert(1, nil)) }

    before do
      allow(described_class).to receive(:new).and_return subject
      allow(subject).to receive(:errors).and_call_original

      result
    end

    it 'initializes an email validator with the provided arguments' do
      expect(described_class).to have_received(:new).with(*params)
    end

    it 'calls errors on the email validator' do
      expect(subject).to have_received :errors
    end

    it 'returns the result of calling errors on the validator' do
      expect(subject.errors).to eq result
    end
  end

  describe '#valid?' do
    context 'when using the default regex' do
      let(:options) { true }

      context 'when the email is valid' do
        let(:email) { valid_email }

        specify { expect(subject.valid?).to eq true }
      end

      context 'when the email is missing a TLD' do
        let(:email) { 'test@example' }

        specify { expect(subject.valid?).to eq false }
      end

      context 'when the email TLD is only one character' do
        let(:email) { 'test@example.c' }

        specify { expect(subject.valid?).to eq false }
      end

      context 'when the email is missing an username' do
        let(:email) { '@example.com' }

        specify { expect(subject.valid?).to eq false }
      end

      context 'when the email is missing the @ symbol' do
        let(:email) { 'test.example.com' }

        specify { expect(subject.valid?).to eq false }
      end
    end

    context 'when using a custom regex' do
      let(:options) { { with: /.+\@.+/ } }

      context 'and the email qualifies' do
        let(:email) { 'test@example' }

        specify { expect(subject.valid?).to eq true }
      end

      context 'and the email does not qualify' do
        let(:email) { 'test$example' }

        specify { expect(subject.valid?).to eq false }
      end
    end
  end

  describe '#errors' do
    context 'when the model has a valid email' do
      let(:email) { valid_email }

      it 'returns an empty error hash' do
        expect(subject.errors).to eq({})
      end
    end

    context 'when the model has an invalid email' do
      let(:email) { invalid_email }

      it 'returns an array of errors for email' do
        expect(subject.errors).to eq(email: ['must be an email address'])
      end
    end

    context 'when provided a custom error message' do
      let(:options) { { message: custom_message } }
      let(:custom_message) { 'this is a custom message' }

      context 'and the email is invalid' do
        let(:email) { invalid_email }

        it 'returns errors with the custom message' do
          expect(subject.errors).to eq(email: [custom_message])
        end
      end
    end
  end
end
