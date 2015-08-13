require 'spec_helper'
require 'volt/extra_core/array'

describe Array do
  describe '#sum' do
    it 'calculates sum of array of integers' do
      expect([1, 2, 3].sum).to eq(6)
    end
  end

  describe "#to_sentence" do
    it 'should return an empty string' do
      expect([].to_sentence).to eq('')
    end

    it 'should return a single entry' do
      expect([1].to_sentence).to eq('1')
    end

    it 'should combine an array into a string with a conjunection and commas' do
      expect([1,2,3].to_sentence).to eq('1, 2, and 3')
    end

    it 'should allow you to build an incorrect sentence' do
      expect([1,2,3].to_sentence(oxford: false)).to eq('1, 2 and 3')
    end

    it 'let you change the conjunction' do
      expect([1,2,3].to_sentence(conjunction: 'or')).to eq('1, 2, or 3')
    end

    it 'let you change the comma' do
      expect([1,2,3].to_sentence(comma: '!')).to eq('1! 2! and 3')
    end
  end
end
