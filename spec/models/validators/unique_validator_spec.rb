require 'spec_helper'

unless RUBY_PLATFORM == 'opal'
  class Fridge < Volt::Model
    validate :name, unique: true
  end

  describe 'unique spec' do
    it 'should reject save if there are records with existing attributes already' do
      store._fridges << { name: 'swift' }
      fridge = store._fridges.buffer name: 'swift'
      fridge.save!.then do
        expect(false).to be_true
      end.fail do
        expect(true).to be_true
      end
    end

    it 'should not increase count of the total records in the store' do
      store._fridges << { name: 'swift' }
      store._fridges << { name: 'swift' }
      expect(store._fridges.count.sync).to eq(1)
    end
  end
end
