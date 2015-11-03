require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  # TODO: this should run fine under opal

  module Volt
    module Persistors
      describe Page do
        describe '#where' do
          it 'searches for records in the page collection with the given values' do
            juan  = Volt::Model.new(name: 'Juan', city: 'Quito', age: 13)
            pedro = Volt::Model.new(name: 'Pedro', city: 'Quito', age: 15)
            jose  = Volt::Model.new(name: 'Jose', city: 'Quito', age: 13)

            the_page._items = [jose, juan, pedro]

            expect(the_page._items.where(age: 13, city: 'Quito')).to match_array [juan, jose]
          end
        end
      end
    end
  end

end
