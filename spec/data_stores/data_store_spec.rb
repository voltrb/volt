require 'spec_helper'
require 'volt/data_stores/data_store'

describe Volt::DataStore do
  it 'should resolve data store from config' do
    config = double("config")
    expect(Volt).to receive(:config) { config }
    expect(config).to receive(:db_driver) { 'mongo' }

    driver = double("mongo_driver")

    expect(Volt::DataStore::MongoDriver).to receive(:fetch) { driver }

    data_store = Volt::DataStore.fetch

    expect(data_store).not_to be_nil
    expect(data_store).to eq(driver)
  end
end
