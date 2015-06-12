require 'spec_helper'

describe Volt::ReactiveHash do
  it 'should clear' do
    a = Volt::ReactiveHash.new
    a[:name] = 'Bob'

    expect(a[:name]).to eq('Bob')
    a.clear
    expect(a[:name]).to eq(nil)
  end

  it 'should return to_json' do
    a = Volt::ReactiveHash.new({name: 'bob'})
    expect(a.to_json).to eq("{\"name\":\"bob\"}")
  end
end
