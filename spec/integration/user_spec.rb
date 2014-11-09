if ENV['BROWSER']
  require 'spec_helper'

  describe "user accounts", type: :feature, sauce: true do
    it 'should create an account' do
      visit '/'

      click_link 'Login'

      click_link 'Signup here'

      fields = all(:css, 'form .form-control')

      fields[0].set('test@test.com')
      fields[1].set('awes0mesEcRet')
      fields[2].set('Test Account')
      sleep 5
    end
  end

end