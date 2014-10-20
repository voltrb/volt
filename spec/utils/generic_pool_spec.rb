require 'volt/utils/generic_pool'

class PoolTest < Volt::GenericPool
  def create(collection, query, other = nil)
    Object.new
  end
end

describe Volt::GenericPool do

  before do
    @pool_test = PoolTest.new
  end

  it 'should insert nested for fast lookup at a path' do
    item1 = @pool_test.lookup('_items', 'one')
    expect(@pool_test.instance_variable_get('@pool')).to eq('_items' => { 'one' => item1 })
  end

  it 'should retrieve the same item both times' do
    item1 = @pool_test.lookup('_items', {})
    item2 = @pool_test.lookup('_items', {})
    expect(item1.object_id).to eq(item2.object_id)
  end

  it 'should recreate after being removed' do
    item1 = @pool_test.lookup('_items', {})
    item2 = @pool_test.lookup('_items', {})
    expect(item1.object_id).to eq(item2.object_id)

    @pool_test.remove('_items', {})
    item3 = @pool_test.lookup('_items', {})
    expect(item3.object_id).to_not eq(item2.object_id)
  end

  it 'should remove all of the way down' do
    @pool_test.instance_variable_set('@pool', name: { ok: true }, yep: true)

    @pool_test.remove(:name, :ok)

    expect(@pool_test.instance_variable_get('@pool')).to eq(yep: true)
  end

  it 'should lookup all items at a path' do
    item1 = @pool_test.lookup('_items', '_some', name: 'bob')
    item2 = @pool_test.lookup('_items', '_some', name: 'jim')

    expect(@pool_test.lookup_all('_items', '_some')).to eq([item1, item2])
  end
end
