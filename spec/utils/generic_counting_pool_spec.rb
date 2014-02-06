require 'volt/utils/generic_counting_pool'

class CountingPoolTest < GenericCountingPool
  def create(collection, query)
    return Object.new
  end
end

describe GenericCountingPool do
  before do
    @pool_test = CountingPoolTest.new
  end
  
  it "should only remove items when the same number have been removed as have been added" do
    item1 = @pool_test.lookup('_items', 'one')
    item2 = @pool_test.lookup('_items', 'one')
    expect(@pool_test.instance_variable_get('@pool')).to_not eq({})

    @pool_test.remove('_items', 'one')
    expect(@pool_test.instance_variable_get('@pool')).to_not eq({})

    @pool_test.remove('_items', 'one')
    expect(@pool_test.instance_variable_get('@pool')).to eq({})
    
  end
end
