require 'spec_helper'

describe Volt::InclusionValidator do
  subject { Volt::InclusionValidator.validate(*use_params) }
  let(:use_params) { [model, field_name, options] }

  let(:model) { Volt::Model.new name: name }
  let(:field_name) { :name }
  let(:name) { 'John' }

  describe '.validate' do
    describe 'when options is an array' do
      let(:options) { %w(John Susie Mary) }

      describe 'when name is "John"' do
        let(:name) { 'John' }
        it { expect(subject).to eq({}) }
      end

      describe 'when name is "Bill"' do
        let(:name) { 'Bill' }
        it do
          expect(subject).to eq(name: ['must be one of John, Susie, Mary'])
        end
      end
    end

    describe 'when options is a Hash' do
      let(:options) do
        { in: %w(John Susie Mary), message: 'Choose one from the list.' }
      end

      describe 'when name is "John"' do
        let(:name) { 'John' }
        it { expect(subject).to eq({}) }
      end

      describe 'when name is "Bill"' do
        let(:name) { 'Bill' }
        it do
          expect(subject).to eq(name: ['Choose one from the list.'])
        end
      end
    end

    describe 'when options not a Fixnum or a Hash' do
      let(:options) { 'string' }

      it 'raises an exception' do
        expect { subject }.to raise_error(
          RuntimeError,
          'The arguments to inclusion validator must be an array or a hash'
        )
      end
    end
  end
end
