if ENV['BROWSER']
  require 'spec_helper'

  describe 'cookies collection', type: :feature, sauce: true do
    if ENV['BROWSER'] != 'phantom'
      # TODO: fails in phantom for some reason
      it 'should add' do
        visit '/'

        click_link 'Cookies'

        fill_in('cookieName', with: 'one')
        fill_in('cookieValue', with: 'one')
        click_button 'Add Cookie'

        expect(page).to have_content('one: one')

        # Reload the page
        page.evaluate_script('document.location.reload()')

        # Check again
        expect(page).to have_content('one: one')
      end
    end

    it 'should delete cookies' do
      visit '/'

      click_link 'Cookies'

      fill_in('cookieName', with: 'two')
      fill_in('cookieValue', with: 'two')
      click_button 'Add Cookie'

      expect(page).to have_content('two: two')

      find('.cookieDelete').click

      expect(page).to_not have_content('two: two')

      # Reload the page
      page.evaluate_script('document.location.reload()')

      expect(page).to_not have_content('two: two')

    end
  end
end