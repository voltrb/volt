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
          expect(subject).to eq({count: ['must be a number']})
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

      # Fails on opal because no True/False class
      # describe 'when passing in multiple types' do
      #   let(:options) do
      #     { types: [TrueClass, FalseClass] }
      #   end
      #   let(:count) { 'a string' }

      #   it do
      #     expect(subject).to eq({count: ['must be true or false']})
      #   end
      # end

      describe 'when passing in Volt::Boolean' do
        let(:options) do
          { type: Volt::Boolean }
        end
        let(:count) { 'a string' }

        it do
          expect(subject).to eq({count: ['must be true or false']})
        end
      end

      describe 'when passing in multiple types' do
        let(:options) do
          { types: [String, Float] }
        end
        let(:count) { 1..1 }

        it do
          expect(subject).to eq({count: ['must be a String or a number']})
        end
      end

      describe 'when passing in multiple types with nil' do
        let(:options) do
          { types: [String, Float, NilClass] }
        end
        let(:count) { 1..1 }

        it do
          expect(subject).to eq({count: ['must be a String or a number']})
        end
      end

    end
  end
end
