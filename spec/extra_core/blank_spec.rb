require 'spec_helper'

describe "blank" do
  it 'should report blank when blank' do
    expect('  '.blank?).to eq(true)
  end

  it 'should report not blank when not blank' do
    expect('  text '.blank?).to eq(false)
  end
end