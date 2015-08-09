require 'spec_helper'

describe 'events and bubbling', type: :feature, sauce: true do
  it 'should bubble events through the dom' do
    visit '/events'

    click_button 'Run Some Event'

    expect(page).to have_content('ran some_event')
  end

  it 'should let you specify an e- handler on components' do
    visit '/events'

    click_button 'Run Other Event'

    expect(page).to have_content('ran other_event')
  end
end