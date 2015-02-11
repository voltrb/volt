require 'spec_helper'
require 'models/validators/shared_examples_for_validators'

describe Volt::EmailValidator do
  subject { described_class.new(*init_params) }
  let(:init_params) { [model, field_name] }

  let(:model) { Volt::Model.new email: email }
  let(:field_name) { :email }
  let(:options) { true }

  let(:email) { field_content }
  let(:field_contet) { valid_email }
  let(:valid_email) { 'test@example.com' }
  let(:invalid_email) { 'test@example-com' }

  let(:validate) { described_class.validate(*params) }
  let(:params) { [model, field_name, options] }
  let(:message) { 'must be an email address' }

  it_behaves_like 'a format validator'

  before do
    allow(described_class).to receive(:new).and_return subject
  end

  context 'when the email is valid' do
    let(:email) { valid_email }

    specify { expect(validate).to eq({}) }

    context 'and when no override criteria is provided' do
      before { validate }

      it 'should have no errors' do
        expect(subject.errors).to eq({})
      end

      specify { expect(subject).to be_valid }
    end
  end

  context 'when the email is missing a TLD' do
    let(:email) { 'test@example' }

    specify { expect(validate).to eq(field_name => [message]) }
  end

  context 'when the email TLD is only one character' do
    let(:email) { 'test@example.c' }

    specify { expect(validate).to eq(field_name => [message]) }
  end

  context 'when the email is missing an username' do
    let(:email) { '@example.com' }

    specify { expect(validate).to eq(field_name => [message]) }
  end

  context 'when the email is missing the @ symbol' do
    let(:email) { 'test.example.com' }

    specify { expect(validate).to eq(field_name => [message]) }
  end
end
