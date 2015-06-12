require 'spec_helper'

describe Volt::TypeValidator do
  subject { Volt::TypeValidator.validate(*use_params) }
  let(:use_params) { [model, field_name, options] }

  let(:model) { Volt::Model.new count: count }
  let(:field_name) { :count }
  let(:name) { 'John Doe' }

  describe '.validate' do
    describe 'when options is a Numeric' do
      let(:options) { Numeric }

      describe 'when count is a Numeric' do
        let(:count) { 5 }
        it { expect(subject).to eq({}) }
      end

      describe 'when count is a string' do
        let(:count) { 'Cats' }
        it do
          expect(subject).to eq({count: ['must be of type Numeric']})
        end
      end
    end

    describe 'when options is a Hash' do
      let(:options) do
        { type: Numeric, message: 'must be a number' }
      end

      describe 'when count is a Numeric' do
        let(:count) { 5 }
        it { expect(subject).to eq({}) }
      end

      describe 'when count is a string' do
        let(:count) { 'Cats' }
        it do
          expect(subject).to eq(count: ['must be a number'])
        end
      end
    end
  end
end
