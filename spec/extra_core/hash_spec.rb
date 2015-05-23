require 'spec_helper'

describe Hash do
  it 'should return a hash without the speicified keys' do
    a = {one: 1, two: 2, three: 3}

    expect(a.without(:one, :three)).to eq({two: 2})
  end
end