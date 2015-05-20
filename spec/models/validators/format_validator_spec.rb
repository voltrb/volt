require 'spec_helper'
require 'models/validators/shared_examples_for_validators'

# test fake used for edge cases where default_options are not Hash types.
# Feel free to append stub methods to this class as needed for testing.
class SpecValidator < Volt::FormatValidator
  def default_options
    "No hash here, no sir!"
  end
end

describe Volt::FormatValidator do
  subject { described_class.new(*init_params) }

  let(:init_params) { [model, field_name] }
  let(:validate_params) { [model, field_name, options] }

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

  context 'when default_options is not a Hash' do
    it 'returns the options hash instead of default_options' do
      user = Volt::Model.new(email: "rick@nolematad.io")
      validator = SpecValidator.new(user, 'email')
      options = { with: /.+@.+/, message: 'must include an @ symbol' }
      results = validator.apply(options).errors
      expect(results.empty?).to be_truthy
    end
  end
end
