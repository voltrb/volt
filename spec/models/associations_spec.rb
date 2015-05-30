require 'spec_helper'

class ::Person < Volt::Model
  has_many :addresses
end

class ::Address < Volt::Model
  belongs_to :person
end

describe Volt::Associations do
  if RUBY_PLATFORM != 'opal'
    before do
      store._people! << { name: 'Jimmy' }
      @person = store._people[0].sync
      @person._addresses! << { city: 'Bozeman' }
      @person._addresses << { city: 'Portland' }
    end

    it 'should associate via belongs_to' do
      address = store._addresses!.fetch_first.sync

      expect(address.person.sync.id).to eq(@person.id)
    end

    it 'should associate via has_many' do
      store._people!.first do |person|

        addresses = person.addresses.all
        expect(addresses.size.sync).to eq(2)
        expect(addresses[0]._city.sync).to eq('Bozeman')
      end
    end

    it 'warns users if persistor is not a ModelStore' do
      store = Volt::Model.new({}, persistor: Volt::Persistors::Flash)
      expect do
        store.send(:association_with_root_model, :blah)
      end.to raise_error("blah currently only works on the store and page collection "\
                         "(support for other collections coming soon)")
    end

    # it 'should assign the reference_id for has_many' do
    #   bob = Person.new
    #   bob.addresses << {:street => '1234 awesome street'}
    #   puts "Bob: #{bob.inspect} - #{bob.addresses.size}"
    #   expect(bob.addresses[0].person_id).to eq(bob.id)
    #   expect(bob.id).to_not eq(nil)
    # end
  end
end
