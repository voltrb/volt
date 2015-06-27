require 'spec_helper'


  def count_occurences(str, find)
    count = 0

    loop do
      index = str.index(find)

      break unless index
      count += 1
      str = str[index+1..-1]
    end

    count
  end

describe Promise do
  it 'should allow you to call methods that will be called on the resolved value and return a new promise' do
    a = Promise.new.resolve(5)

    float_promise = a.to_f
    expect(float_promise.class).to eq(Promise)
    float_promise.then do |val|
      expect(val).to eq(5)
    end
  end

  it 'should patch inspect on Promise so that nested Promise are shown as a single promise' do
    a = Promise.new
    b = Promise.new.then { a }
    a.resolve(1)
    b.resolve(2)

    # There is currently an infinity loop in scan in opal.
    # https://github.com/opal/opal/issues/457
    # TODO: Remove when opal 0.8 comes out.
    # expect(b.inspect.scan('Promise').size).to eq(1)

    expect(count_occurences(b.inspect, 'Promise')).to eq(1)
  end

  it 'should not respond to comparitors' do
    [:>, :<].each do |comp|
      a = Promise.new
      expect do
        a.send(comp, 5)
      end.to raise_error(NoMethodError)
    end
  end

  it 'should proxy methods on promises' do
    a = Promise.new
    expect do
      a.something
    end.not_to raise_error
  end

  describe "unwrap" do
    it 'should raise an exception if calling unwrap on an unrealized promise' do
      a = Promise.new
      expect do
        a.unwrap
      end.to raise_error(Promise::UnrealizedPromiseException, '#unwrap called on a promise that has yet to be realized.')
    end

    it 'should return the value for a resolved promise' do
      a = Promise.value(5)

      expect(a.unwrap).to eq(5)
    end

    it 'should raise an error from a rejected promise' do
      a = Promise.error(Exception.new('broke it'))
      expect do
        a.unwrap
      end.to raise_error(Exception, 'broke it')
    end
  end
end