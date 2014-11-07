# This spec fails on sauce randomly, disable for now
if ENV['BROWSER'] && ENV['BROWSER'] != 'sauce'
  require 'spec_helper'

  describe 'flash messages', type: :feature, :sauce => true do
    it 'should flash on sucesses, notices, warnings, and errors' do
      visit '/'

      click_link 'Flash'

      click_link 'Flash Notice'
      expect(page).to have_content('A notice message')
      find('.alert').click
      expect(page).to_not have_content('A notice message')

      click_link 'Flash Success'
      expect(page).to have_content('A success message')
      find('.alert').click
      expect(page).to_not have_content('A success message')

      click_link 'Flash Warning'
      expect(page).to have_content('A warning message')
      find('.alert').click
      expect(page).to_not have_content('A warning message')

      click_link 'Flash Error'
      expect(page).to have_content('An error message')
      find('.alert').click
      expect(page).to_not have_content('An error message')

    end
  end
end