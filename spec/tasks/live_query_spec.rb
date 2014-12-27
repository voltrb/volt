if RUBY_PLATFORM != 'opal'
  describe 'LiveQuery' do
    before do
      load File.join(File.dirname(__FILE__), '../../app/volt/tasks/live_query/live_query.rb')
    end

    it 'should run a query' do
      pool = double('volt/pool')
      data_store = double('volt/data store')

      expect(data_store).to receive(:query).with('_items', {}).and_return([
        { '_id' => 0, '_name' => 'one' }
      ])

      live_query = LiveQuery.new(pool, data_store, '_items', {})
    end
  end
end
