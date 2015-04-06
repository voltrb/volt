require 'spec_helper'

describe Volt::Buffer do
  it 'should let you pass a block that evaluates to the then of the promise' do
    buffer = the_page._items!.buffer

    count = 0
    result = buffer.save! do
      count += 1
    end

    expect(count).to eq(1)
    expect(result.class).to eq(Promise)
  end
end