require 'spec_helper'

if RUBY_PLATFORM != 'opal'
  describe 'LiveQuery' do
    it 'should run a query' do
      pool = double('volt/pool')
      data_store = double('volt/data store')

      expect(data_store).to receive(:query).with('_items', []).and_return([
        { 'id' => 0, '_name' => 'one' }
      ])

      live_query = Volt::LiveQuery.new(volt_app, pool, data_store, '_items', {})
    end
  end
end
