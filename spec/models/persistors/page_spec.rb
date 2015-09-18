require 'spec_helper'

module Volt
  module Persistors
    describe Page do
      describe '#where' do
        it 'searches for records in the page collection with the given values' do
          juan  = Volt::Model.new(name: 'Juan', city: 'Quito', age: 13)
          pedro = Volt::Model.new(name: 'Pedro', city: 'Quito', age: 15)
          jose  = Volt::Model.new(name: 'Jose', city: 'Quito', age: 13)

          page = described_class.new [jose, juan, pedro]

          expect(page.where age: 13, city: 'Quito').to match_array [juan, jose]
        end
      end
    end
  end
end
