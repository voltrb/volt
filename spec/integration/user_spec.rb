if ENV['BROWSER']
  require 'spec_helper'

  describe "user accounts", type: :feature, sauce: true do
    before(:all) do
      # Clear out db
      DataStore.new.drop_database
    end

    after(:all) do
      # Clear out db
      DataStore.new.drop_database
    end

    it 'should create an account' do
      visit '/'

      click_link 'Login'

      click_link 'Signup here'

      fields = all(:css, 'form .form-control')

      fields[0].set('test@test.com')
      fields[1].set('awes0mesEcRet')
      fields[2].set('Test Account 9550')

      click_button 'Signup'

      sleep 10

      expect(page).to have_content('Test Account 9550')
    end

    # it 'should login and logout' do
    #   visit '/'
    #
    #   click_link 'Login'
    #
    #   fields = all(:css, 'form .form-control')
    #   fields[0].set('test@test.com')
    #   fields[1].set('awes0mesEcRet')
    #   click_button 'Login'
    #
    #   sleep 10
    #
    #   expect(page).to have_content('Test Account 9550')
    # end
  end

end