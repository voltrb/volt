if ENV['BROWSER']
  require 'spec_helper'

  describe "bindings test", :type => :feature do
    it "should change the title when changing pages" do
      visit '/'

      expect(page).to have_title 'KitchenSink - KitchenSink'
      click_link 'Bindings'

      expect(page).to have_title 'Bindings - KitchenSink'

    end
  end
end