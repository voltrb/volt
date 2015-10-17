require 'spec_helper'

describe 'lifecycle callbacks', type: :feature, sauce: true do

  context 'with a user' do
    before do
      # Add the user
      store._users! << { email: 'test@test.com', password: 'awes0mesEcRet', name: 'Test Account 9550' }
    end

    it 'should trigger a user_connect event when a user logs in and a user_disconnect event when a user logs out' do
      visit '/'

      click_link 'Login'

      fields = all(:css, 'form .form-control')
      fields[0].set('test@test.com')
      fields[1].set('awes0mesEcRet')
      click_button 'Login'

      visit '/callbacks'

      expect(page).to have_content('user_connect')

      click_link 'Test Account 9550'
      click_link 'Logout'

      expect(page).to have_content('user_disconnect')
    end
  end
end
