if ENV['BROWSER'] && ENV['BROWSER'] != 'phantom'
  require 'spec_helper'

  describe 'url features', type: :feature, sauce: true do
    it 'should update the page when using the back button' do
      visit '/'
      expect(current_url).to match(/\/$/)

      click_link 'Bindings'
      expect(current_url).to match(/\/bindings$/)
      expect(page).to have_content('Checkbox')

      click_link 'Todos'
      expect(current_url).to match(/\/todos$/)
      expect(page).to have_content('Todos Example')

      # "Click" back button
      page.evaluate_script('window.history.back()')

      click_link 'Bindings'
      expect(current_url).to match(/\/bindings$/)
      expect(page).to have_content('Checkbox')

      # "Click" back button
      page.evaluate_script('window.history.back()')

      expect(current_url).to match(/\/$/)
    end

  end
end