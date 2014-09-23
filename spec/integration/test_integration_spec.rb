if ENV['BROWSER']
  require 'spec_helper'

  describe "integration test", :type => :feature do
    it "should load the page" do
      visit '/'

      expect(page).to have_content('Home')
      # expect(page).to have_content('About')
      # page.has_text?('About')
      # puts "HAS CONTENT: #{page.has_text?('About')}"
    end
  end
end
