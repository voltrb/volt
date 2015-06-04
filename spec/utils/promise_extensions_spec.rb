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

  it 'delegates to_json to the value or error (respectively)' do
    a = Promise.new.tap { |p| p.resolve(hello: 'world') }
    expect(a.to_json).to eq("{\"hello\":\"world\"}")
    b = Promise.new.tap { |p| p.reject(goodbye: 'jupiter') }
    expect(b.to_json).to eq("{\"goodbye\":\"jupiter\"}")
    expect(Promise.new.to_json).to eq('null')
  end
end
