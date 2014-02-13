if ENV['IN_BROWSER']
  require 'spec_helper'

  describe "integration test", :type => :feature do
    it "should load the page" do
      visit '/'
    
      expect(page).to have_content('Home')
    end
  end
end