require 'volt/utils/generic_pool'

describe GenericPool do
  class PoolTest < GenericPool
    def create(collection, query)
      return Object.new
    end
  end

  before do
    @pool_test = PoolTest.new
  end
  
  it "should retrieve the same item both times" do
    item1 = @pool_test.lookup('_items', {})    
    item2 = @pool_test.lookup('_items', {})
    expect(item1.object_id).to eq(item2.object_id)    
  end
  
  it "should recreate after being removed" do
    item1 = @pool_test.lookup('_items', {})    
    item2 = @pool_test.lookup('_items', {})
    expect(item1.object_id).to eq(item2.object_id)
    
    @pool_test.remove('_items', {})
    item3 = @pool_test.lookup('_items', {})
    expect(item3.object_id).to_not eq(item2.object_id)
  end
end