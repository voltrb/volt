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
end
