require 'spec_helper'

describe 'saving', type: :feature, sauce: true do
  it 'should return an error as an instance of Volt::Error' do
    visit '/save'

    fill_in 'post_title', with: 'ok'

    click_button 'Save'

    expect(page).to have_content('#<Volt::Errors {"title"=>["must be at least 5 characters"]}>')
  end
end