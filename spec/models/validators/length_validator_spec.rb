require 'spec_helper'

describe Volt::LengthValidator do
  subject { Volt::LengthValidator.validate(*use_params) }
  let(:use_params) { [model, field_name, options] }

  let(:model) { Volt::Model.new name: name }
  let(:field_name) { :name }
  let(:name) { 'John Doe' }

  describe '.validate' do
    describe 'when options is a Fixnum' do
      let(:options) { 5 }

      describe 'when name is "John Doe"' do
        let(:name) { 'John Doe' }
        it { expect(subject).to eq({}) }
      end

      describe 'when name is "John"' do
        let(:name) { 'John' }
        it do
          expect(subject).to eq(name: ['must be at least 5 characters'])
        end
      end
    end

    describe 'when options is a Hash' do
      let(:options) do
        { length: 5, maximum: 10 }
      end

      describe 'when name is "John Doe"' do
        let(:name) { 'John Doe' }
        it { expect(subject).to eq({}) }
      end

      describe 'when name is "John"' do
        let(:name) { 'John' }
        it do
          expect(subject).to eq(name: ["must be at least 5 characters"])
        end
      end

      describe 'when name is "Zach Galifianakis"' do
        let(:name) { 'Zach Galifianakis' }
        it do
          expect(subject).to eq(name: ['must be less than 10 characters'])
        end
      end
    end

    describe 'when options not a Fixnum or a Hash' do
      let(:options) { 'string' }

      it 'raises an exception' do
        expect { subject }.to raise_error(
          RuntimeError,
          'The arguments to length must be a number or a hash'
        )
      end
    end
  end
end
