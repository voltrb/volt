require 'spec_helper'

describe 'user accounts', type: :feature, sauce: true do
  it 'should create an account' do
    visit '/'

    click_link 'Login'

    click_link 'Signup here'

    fields = all(:css, 'form .form-control')

    fields[0].set('test@test.com')
    fields[1].set('awes0mesEcRet')
    fields[2].set('Test Account 9550')

    click_button 'Signup'

    expect(page).to have_content('Test Account 9550')
  end


  it 'should fail to create an account without a valid email and password' do
    visit '/'

    click_link 'Login'
    click_link 'Signup here'

    expect(page).to_not have_content('must be at least 8 characters')

    fields = all(:css, 'form .form-control')

    fields[0].set('test')
    fields[1].set('awe')
    fields[2].set('Tes')

    # some capybara drivers don't trigger blur correctly
    page.execute_script("$('.form-control').blur()")

    expect(page).to have_content('must be at least 8 characters')
  end

  describe "with a user" do
    before do
        # Add the user
        store._users! << { email: 'test@test.com', password: 'awes0mesEcRet', name: 'Test Account 9550' }
    end

    it 'should login and logout' do
      visit '/'

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

    it 'should show an error for invalid email' do
      visit '/'
      click_link 'Login'

      fields = all(:css, 'form .form-control')
      fields[0].set('notausersemail@gmail.com')
      fields[1].set('awes0mesEcRet')
      click_button 'Login'

      expect(page).to have_content('User could not be found')
    end

    it 'should show an error for an invalid password' do
      visit '/'
      click_link 'Login'

      fields = all(:css, 'form .form-control')
      fields[0].set('test@test.com')
      fields[1].set('wrongpassword')
      click_button 'Login'

      expect(page).to have_content('Password did not match')
    end

    it 'should let you login from a task' do
      visit '/login_from_task'

      click_button 'Login First User'

      expect(page).to have_content('Test Account 9550')
    end
  end

end
