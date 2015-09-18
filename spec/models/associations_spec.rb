require 'spec_helper'

class ::Person < Volt::Model
  has_many :addresses
end

class ::Address < Volt::Model
  belongs_to :person
  has_one :zip_info
end

class ::AddressBelongToOption < Volt::Model
  belongs_to :someone, collection: :person, foreign_key: :id, local_key: :some_weird_id
end

class ::ZipInfo < Volt::Model
  belongs_to :address
end

describe Volt::Associations do
  if RUBY_PLATFORM != 'opal'
    describe "with samples" do
      before do
        @person = Person.new(name: 'Jimmy')
        store.people << @person
        @person.addresses << Address.new(city: 'Bozeman')
        @person.addresses << Address.new(city: 'Portland')
      end

      it 'should associate via belongs_to' do
        address = store.addresses.first.sync

        expect(address.person_id).to eq(@person.id)
        expect(address.person.sync.id).to eq(@person.id)
      end

      it 'should support collection and foreign_key on belongs_to' do
        @person = Person.new(name: 'Jimmy')
        store.people << @person
        @location = AddressBelongToOption.new(someone: @person)

        store.address_belong_to_options << @location

        @location.someone.then do |someone|
          expect(someone.id).to eq(@person.id)
        end
      end

      it 'should raise an exception if you try to use an association on a model that isn\'t associated with a repository'

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
    end

    it 'should support has_one' do
      address = store.addresses.create({street: '223344 Something St'}).sync

      zip_info = store.zip_infos.create({zip: '29344', address_id: address.id}).sync

      address2 = store.addresses.first.sync
      expect(address2.zip_info.sync.id).to eq(zip_info.id)
    end

    it 'should raise an exception when setting up a plural has one' do
      expect do
        Address.send(:has_one, :isotopes)
      end.to raise_error(NameError, "has_one takes a singluar association name")
    end

    it 'should assign the reference_id for has_many' do
      bob = store.people.create.sync

      expect(bob.path).to eq([:people, :[]])
      address = bob.addresses.create({street: '1234 awesome street'})

      expect(bob.addresses[0].sync.person_id).to eq(bob.id)
      expect(bob.id).to_not eq(nil)
    end
  end
end
