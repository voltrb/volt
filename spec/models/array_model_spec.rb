require 'spec_helper'

# TODO: ArrayModel and Model specs are mixed in model_spec atm.  Need to move
# ArrayModel specs here.
describe Volt::ArrayModel do
  unless RUBY_PLATFORM == 'opal'
    it 'should return a Promise for empty? on store' do
      expect(store._posts.empty?.class).to eq(Promise)
    end
  end

  it 'should reactively update .empty? when an item is added to a collection' do
    Volt::Computation.flush!
    count = 0
    comp = -> { the_page._names.empty? ; count += 1 }.watch!

    expect(count).to eq(1)

    the_page._names.create({name: 'Bob'})

    Volt::Computation.flush!
    expect(count).to eq(2)
  end

  it 'should return the index of a model' do
    array_model = Volt::ArrayModel.new([1,2,3])

    expect(array_model.index(2)).to eq(1)
  end


  it 'should flatten' do
    array = Volt::ArrayModel.new([])

    array << Volt::ArrayModel.new([Volt::ArrayModel.new([1,2]), Volt::ArrayModel.new([3])])
    array << Volt::ArrayModel.new([Volt::ArrayModel.new([4,5]), Volt::ArrayModel.new([6])])

    expect(array.flatten.size).to eq(6)
    expect(array.to_a.flatten.size).to eq(6)
  end

  it "should return nil for last on empty array" do
    array = Volt::ArrayModel.new([])
    expect( array.last ).to be nil
  end
end
