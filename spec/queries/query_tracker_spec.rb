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
        @items.reject! { |item| ids.include?(item[:id]) }
      end

      def notify_added(index, data, skip_channel)
        @items.insert(index, data)
      end

      def notify_moved(id, index, skip_channel)
        item = @items.find { |item| item[:id] == id }
        @items.delete(item)

        @items.insert(index, item)
      end

      def notify_changed(id, data, skip_channel)
        item = @items.find { |item| item[:id] == id }
        idx  = @items.index(item)
        @items.delete(item)
        @items.insert(idx, data)
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
        { id: 1, name: 'one' }
      ]

      expect(@live_query.items).to eq([])

      @query_tracker.run

      expect(@live_query.items).to eq(@items)
    end

    it 'should remove items' do
      @items = [
        { id: 1, name: 'one' },
        { id: 2, name: 'two' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { id: 2, name: 'two' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end

    it 'should move items' do
      @items = [
        { id: 1, name: 'one' },
        { id: 2, name: 'two' },
        { id: 3, name: 'three' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { id: 2, name: 'two' },
        { id: 3, name: 'three' },
        { id: 1, name: 'one' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end

    it 'should handle complex transforms' do
      @items = [
        { id: 1, name: 'one' },
        { id: 2, name: 'two' },
        { id: 3, name: 'three' },
        { id: 4, name: 'four' },
        { id: 5, name: 'five' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)

      @items = [
        { id: 7, name: 'seven' },
        { id: 4, name: 'four' },
        { id: 1, name: 'one' },
        { id: 5, name: 'five' },
        { id: 3, name: 'three' },
        { id: 6, name: 'five' }
      ]
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end

    it 'should notify data hash has changed' do
      @items = [
        { id: 1, name: 'one' },
        { id: 2, name: 'two' },
        { id: 3, name: 'three' },
        { id: 4, name: 'four' },
        { id: 5, name: 'five' }
      ]
      @query_tracker.run
      @items = [
        { id: 1, name: 'some' },
        { id: 2, name: 'values' },
        { id: 3, name: 'have' },
        { id: 4, name: 'changed' },
        { id: 5, name: 'other' }
      ]
      expect(@live_query.items).to_not eq(@items)
      @query_tracker.run
      expect(@live_query.items).to eq(@items)
    end
  end
end
