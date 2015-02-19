require 'spec_helper'
require 'models/validators/shared_examples_for_validators'

describe Volt::FormatValidator do
  subject { described_class.new(*init_params) }

  let(:init_params) { [ model, field_name ] }
  let(:validate_params) { [ model, field_name, options ] }

  let(:model) { Volt::Model.new field: field_content }
  let(:field_name) { :field }
  let(:options) { regex_opts }

  let(:regex) { /^valid/ }
  let(:proc_regex) { /^valid/ }
  let(:test_proc) { ->(content) { proc_regex.match content } }

  let(:proc_opts) { { with: test_proc, message: proc_message } }
  let(:regex_opts) { { with: regex, message: regex_message } }

  let(:proc_message) { 'proc is invalid' }
  let(:regex_message) { 'regex is invalid' }

  let(:field_content) { valid_content }
  let(:invalid_content) { 'invalid_content' }
  let(:valid_content) { 'valid_content' }

  let(:validate) { described_class.validate(*validate_params) }

  it_behaves_like 'a format validator'

  context 'when no criteria is provided' do
    before { validate }

    it 'should have no errors' do
      expect(subject.errors).to eq({})
    end

    specify { expect(subject).to be_valid }
  end
end