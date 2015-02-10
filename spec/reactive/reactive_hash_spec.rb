require 'spec_helper'

describe Volt::ReactiveHash do
  it 'should clear' do
    a = Volt::ReactiveHash.new
    a[:name] = 'Bob'

    expect(a[:name]).to eq('Bob')
    a.clear
    expect(a[:name]).to eq(nil)
  end
end