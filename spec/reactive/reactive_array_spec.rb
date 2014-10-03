require 'spec_helper'
require 'volt/reactive/reactive_array'

describe ReactiveArray do
  describe "cells" do
    it 'should track dependencies for cells' do
      a = ReactiveArray.new

      count = 0
      values = []
      -> { values << a[0] ; count += 1 }.watch!

      a[0] = 5

      Computation.flush!

      a[0] = 10
      expect(count).to eq(2)
      expect(values).to eq([nil, 5])

      Computation.flush!
      expect(count).to eq(3)
      expect(values).to eq([nil, 5, 10])
    end

    it 'should trigger changed on the last cell when appending' do
      a = ReactiveArray.new([1,2,3])

      values = []
      -> { values << a[3] }.watch!

      expect(values).to eq([nil])

      a << 4
      expect(values).to eq([nil])

      Computation.flush!
      expect(values).to eq([nil, 4])
    end

    it 'should trigger changes for each cell after index after insert' do
      a = ReactiveArray.new([1,2,3])

      values_at_2 = []
      values_at_3 = []
      values_at_4 = []
      -> { values_at_2 << a[2] }.watch!
      -> { values_at_3 << a[3] }.watch!
      -> { values_at_4 << a[4] }.watch!

      expect(values_at_2).to eq([3])
      expect(values_at_3).to eq([nil])
      expect(values_at_4).to eq([nil])

      a.insert(2,1.3,1.7)

      Computation.flush!

      expect(values_at_2).to eq([3,1.3])
      expect(values_at_3).to eq([nil,1.7])
      expect(values_at_4).to eq([nil,3])

    end
  end

  describe "size dependencies" do
    it 'pushing should trigger changed for size' do
      array = ReactiveArray.new
      count = 0

      size_values = []
      -> { size_values << array.size }.watch!

      expect(size_values).to eq([0])

      array << 5

      Computation.flush!
      expect(size_values).to eq([0,1])
    end

    it 'should trigger a size change when deleting' do
      array = ReactiveArray.new([1,2,3])

      size_values = []
      -> { size_values << array.size }.watch!

      expect(size_values).to eq([3])

      array.delete_at(2)

      expect(size_values).to eq([3])
      Computation.flush!
      expect(size_values).to eq([3,2])
    end
  end
end