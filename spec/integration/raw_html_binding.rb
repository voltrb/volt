require 'spec_helper'

describe 'HTML safe/raw', type: :feature do
  it 'should render html with the raw helper' do
    visit '/html_safe'

    expect(page).to have_selector('button[id="examplebutton"]')
  end
end
