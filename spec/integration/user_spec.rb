if ENV['BROWSER']
  require 'spec_helper'

  describe "user accounts", type: :feature, sauce: true do
    before(:each) do
      # Clear out db
      DataStore.new.drop_database
    end

    after(:each) do
      # Clear out db
      DataStore.new.drop_database
    end

    it 'should create an account' do
      visit '/'

      # sleep 300

      click_link 'Login'

      click_link 'Signup here'

      fields = all(:css, 'form .form-control')

      fields[0].set('test@test.com')
      fields[1].set('awes0mesEcRet')
      fields[2].set('Test Account 9550')

      click_button 'Signup'

      expect(page).to have_content('Test Account 9550')
    end

    it 'should login and logout' do
      visit '/'

      # Add the user
      $page.store._users << {email: 'test@test.com', password: 'awes0mesEcRet', name: 'Test Account 9550'}

      click_link 'Login'

      fields = all(:css, 'form .form-control')
      fields[0].set('test@test.com')
      fields[1].set('awes0mesEcRet')
      click_button 'Login'

      expect(page).to have_content('Test Account 9550')

      # Click the logout link
      click_link 'Test Account 9550'
      click_link 'Logout'

      expect(page).to_not have_content('Test Account 9550')
    end
  end

end