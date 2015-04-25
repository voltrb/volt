require 'spec_helper'

describe 'unique spec', type: :feature, sauce: true do
  before do
  end

  it 'should reject save if there are records with existing attributes already' do
    DataStore.new.drop_database
    $page.store._fridges << { name: 'swift' }
    fridge = $page.store._fridges.buffer name: 'swift'
    fridge.save!.then do
      expect(false).to be_true
    end.fail do
      expect(true).to be_true
    end
    DataStore.new.drop_database
  end

  it 'should not increase count of the total records in the store' do
    DataStore.new.drop_database
    $page.store._fridges << { name: 'swift' }
    $page.store._fridges << { name: 'swift' }
    expect($page.store._fridges.count).to eq(1)
    DataStore.new.drop_database
  end
end
