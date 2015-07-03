require 'spec_helper'

# TODO: ArrayModel and Model specs are mixed in model_spec atm.  Need to move
# ArrayModel specs here.
describe Volt::ArrayModel do
  it 'should return a Promise for empty? on store' do
    expect(store._posts.empty?.class).to eq(Promise)
  end

  it 'should reactively update .empty? when an item is added to a collection' do
    count = 0
    comp = -> { the_page._names.empty? ; count += 1 }.watch!

    expect(count).to eq(1)

    the_page._names.create({name: 'Bob'})

    Volt::Computation.flush!
    expect(count).to eq(2)
  end
end