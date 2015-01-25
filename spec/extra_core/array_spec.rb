require 'spec_helper'
require 'volt/extra_core/array'

describe Array do
  describe '#sum' do
    it 'calculates sum of array of integers' do
      expect([1, 2, 3].sum).to eq(6)
    end
  end
end
