require 'spec_helper'

describe Volt::Models::Helpers::Model do
  describe "saved_state" do
    it 'should start not_saved for a buffer' do
      item = the_page._items.buffer
      expect(item.saved_state).to eq(:not_saved)
    end

    it 'should move to saved when the buffer is saved' do
      item = the_page._items.buffer
      item.save!.then do
        expect(item.saved_state).to eq(:saved)
      end
    end

    it 'should start as saved after create' do
      item = the_page._items.create({name: 'One'})

      expect(item.saved_state).to eq(:saved)
    end

    # TODO: because server side model loading is done synchronusly, we can't
    # test the
  end
end