require 'spec_helper'

describe 'sample integration test', type: :feature do
  # An example integration spec, this will only be run if ENV['BROWSER'] is
  # specified.  Current values for ENV['BROWSER'] are 'firefox' and 'phantom'
  it 'should load the page' do
    visit '/'

    expect(page).to have_content('Home')
  end
end
