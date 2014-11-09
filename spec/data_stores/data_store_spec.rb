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

  it 'should fail for unknown driver' do
    config = double("config")
    expect(Volt).to receive(:config).at_least(:once) { config }
    expect(config).to receive(:db_driver).at_least(:once) { 'unknown_driver' }

    expect { Volt::DataStore.fetch }.to raise_error("Database specified in Volt.config.db_driver is not supported: unknown_driver")

  end
end
