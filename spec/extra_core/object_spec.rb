require 'spec_helper'
require 'volt/extra_core/blank'

describe Object do
  it 'should add blank? to all objects' do
    expect(Object.new.blank?).to eq(false)
    expect(nil.blank?).to eq(true)
  end

  it 'should add present? to all objects' do
    expect(Object.new.present?).to eq(true)
    expect(nil.present?).to eq(false)
  end

  it 'should allow you to call .then to get a Promise with the object resolved' do
    promise = 5.then

    expect(promise.resolved?).to eq(true)
    expect(promise.value).to eq(5)
  end

  it 'should allow you to call .then with a block that will yield the promise' do
    5.then do |val|
      expect(val).to eq(5)
    end
  end
end
