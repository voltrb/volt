require 'spec_helper'

describe 'image loading', type: :feature, sauce: true do
  it 'should load images in assets' do
    visit '/images'

    loaded = page.evaluate_script("$('img').get(0).complete")
    expect(loaded).to eq(true)
  end
end