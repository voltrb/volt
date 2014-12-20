require 'volt/utils/generic_counting_pool'

class CountingPoolTest < Volt::GenericCountingPool
  def create(id, name = nil)
    Object.new
  end
end

describe Volt::GenericCountingPool do
  before do
    @count_pool = CountingPoolTest.new
  end

  it 'should lookup and retrieve' do
    item1 = @count_pool.find('one')

    item2 = @count_pool.find('one')
    item3 = @count_pool.find('two')

    expect(item1).to eq(item2)
    expect(item2).to_not eq(item3)
  end

  it 'should only remove items when the same number have been removed as have been added' do
    item1 = @count_pool.find('_items', 'one')
    item2 = @count_pool.find('_items', 'one')
    expect(@count_pool.instance_variable_get('@pool')).to_not eq({})

    @count_pool.remove('_items', 'one')
    expect(@count_pool.instance_variable_get('@pool')).to_not eq({})

    @count_pool.remove('_items', 'one')
    expect(@count_pool.instance_variable_get('@pool')).to eq({})
  end
end
