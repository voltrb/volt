require 'spec_helper'

class ::Person < Volt::Model
end

class ::Address < Volt::Model
  belongs_to :person
end

describe Volt::Associations do
  if RUBY_PLATFORM != 'opal'
    it 'should associate via belongs_to' do
      DataStore.new.drop_database
      $page.store._people << {name: 'Jimmy'}
      person = $page.store._people[0]
      person._addresses << {city: 'Bozeman'}

      address = $page.store._addresses.fetch_first.sync

      expect(address.person.sync._id).to eq(person._id)
    end
  end
end