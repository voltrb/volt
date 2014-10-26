require 'spec_helper'
require 'volt/extra_core/blank'

describe Object do
  it 'should add blank? to all objects' do
    expect(Object.new.blank?).to be_false
    expect(nil.blank?).to be_true
  end

  it 'should add present? to all objects' do
    expect(Object.new.present?).to be_true
    expect(nil.present?).to be_false
  end
end
