if RUBY_PLATFORM != 'opal'
  describe 'LiveQuery' do
    before do
      load File.join(File.dirname(__FILE__), '../../app/volt/tasks/live_query/live_query.rb')
    end

    # LiveQueryStub behaves as the front-end would with the changes to a
    # live query.  Instead of passing changes to the models to the front
    # end, the changes are applied locally, then can be checked to see if
    # the correct transitions have taken place.
    class LiveQueryStub
      attr_reader :collection, :query, :items
      def initialize
        @collection = '_items'
        @query = {}
        @items = []
      end

      def notify_removed(ids, skip_channel)
        # Remove the id's that need to be removed
        @items.reject! { |item| ids.include?(item['_id']) }
      end

      def notify_added(index, data, skip_channel)
        @items.insert(index, data)
      end

      def notify_moved(id, index, skip_channel)
        item = @items.find { |item| item['_id'] == id }
        @items.delete(item)

        @items.insert(index, item)
      end
    end

    before do
      # Setup a live query stub
      @live_query = LiveQueryStub.new
      data_store = double('volt/data store')

      # return an empty collection
      @items = []
      expect(data_store).to receive(:query).at_least(:once) { @items.dup }

      @query_tracker = QueryTracker.new(@live_query, data_store)
      @query_tracker.run
    end

    it 'should add items' do
      @items = [
        { '_id' => 1, '_name' => 'one' }
      ]

      expect(@live_query.items).to eq([])

      @query_tracker.run

      expect(@live_query.items).to eq(@items)
    end

    it 'should remove items' do
      @items = [
        { '_id' => 1, '_name' => 'one' },
        { '_id' => 2, '_name' => 'two' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { '_id' => 2, '_name' => 'two' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end

    it 'should move items' do
      @items = [
        { '_id' => 1, '_name' => 'one' },
        { '_id' => 2, '_name' => 'two' },
        { '_id' => 3, '_name' => 'three' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { '_id' => 2, '_name' => 'two' },
        { '_id' => 3, '_name' => 'three' },
        { '_id' => 1, '_name' => 'one' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end

    it 'should handle complex transforms' do
      @items = [
        { '_id' => 1, '_name' => 'one' },
        { '_id' => 2, '_name' => 'two' },
        { '_id' => 3, '_name' => 'three' },
        { '_id' => 4, '_name' => 'four' },
        { '_id' => 5, '_name' => 'five' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { '_id' => 7, '_name' => 'seven' },
        { '_id' => 4, '_name' => 'four' },
        { '_id' => 1, '_name' => 'one' },
        { '_id' => 5, '_name' => 'five' },
        { '_id' => 3, '_name' => 'three' },
        { '_id' => 6, '_name' => 'five' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end
  end
end
