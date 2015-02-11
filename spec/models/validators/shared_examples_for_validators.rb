require 'spec_helper'

shared_examples_for 'a format validator' do
  let(:regex) { /^valid/ }
  let(:proc_regex) { /^valid/ }
  let(:test_proc) { ->(content) { proc_regex.match content } }

  let(:proc_opts) { { with: test_proc, message: proc_message } }
  let(:regex_opts) { { with: regex, message: regex_message } }

  let(:field_content) { valid_content }
  let(:invalid_content) { 'invalid_content' }
  let(:valid_content) { 'valid_content' }

  let(:proc_message) { 'proc is invalid' }
  let(:regex_message) { 'regex is invalid' }

  before do
    allow(described_class).to receive(:new).and_return subject
  end

  context 'when the only override criterion is a regex' do
    let(:options) { regex_opts }

    before { validate }

    context 'and when the field matches' do
      let(:field_content) { valid_content }

      it 'should have no errors' do
        expect(subject.errors).to eq({})
      end

      specify { expect(subject).to be_valid }
    end

    context 'and when the field does not match' do
      let(:field_content) { invalid_content }

      it 'should report the related error message' do
        expect(subject.errors).to eq field_name => [regex_message]
      end

      specify { expect(subject).to_not be_valid }
    end
  end

  context 'when the only override criterion is a block' do
    let(:options) { proc_opts }

    before { validate }

    context 'and when the field passes the block' do
      let(:field_content) { valid_content }

      it 'should have no errors' do
        expect(subject.errors).to eq({})
      end

      specify { expect(subject).to be_valid }
    end

    context 'and when the field fails the block' do
      let(:field_content) { invalid_content }

      it 'should report the related error message' do
        expect(subject.errors).to eq field_name => [proc_message]
      end

      specify { expect(subject).to_not be_valid }
    end
  end

  context 'when there is both regex and block criteria' do
    let(:options) { [ regex_opts, proc_opts ] }

    before { validate }

    context 'and when the field passes all criteria' do
      let(:field_content) { valid_content }

      it 'should have no errors' do
        expect(subject.errors).to eq({})
      end

      specify { expect(subject).to be_valid }
    end

    context 'and when the field fails the regex' do
      let(:regex) { /^invalid/ }

      it 'should report the related error message' do
        expect(subject.errors).to eq field_name => [regex_message]
      end

      specify { expect(subject).to_not be_valid }
    end

    context 'and when the field fails the block' do
      let(:proc_regex) { /^invalid/ }

      it 'should report the related error message' do
        expect(subject.errors).to eq field_name => [proc_message]
      end

      specify { expect(subject).to_not be_valid }
    end

    context 'and when the field fails both the regex and the block' do
      let(:field_content) { invalid_content }

      it 'should report the regex error message' do
        expect(subject.errors[field_name]).to include regex_message
      end

      it 'should report the proc error message' do
        expect(subject.errors[field_name]).to include proc_message
      end

      specify { expect(subject).to_not be_valid }
    end
  end
end
