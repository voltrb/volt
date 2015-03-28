if ENV['BROWSER']
  require 'spec_helper'

  describe 'rest endpoints', type: :feature, sauce: true do
    it 'should show the page' do
      visit '/rest'
      expect(page).to have_content("this is just some text")
    end
  end
end

