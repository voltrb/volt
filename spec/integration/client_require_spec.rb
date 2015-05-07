require 'spec_helper'

describe 'client require', type: :feature, sauce: true do
  it 'should require code in controllers' do
    visit '/require_test'

    expect(page).to have_content('Date Class: true')
  end
end
