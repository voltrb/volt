require 'spec_helper'

describe 'todos app', type: :feature, sauce: true do
  it 'should add a todo and remove it' do
    visit '/todos'

    fill_in 'newtodo', with: 'Todo 1'
    find('#newtodo').native.send_keys(:return)

    expect(page).to have_content('Todo 1')

    expect(find('#newtodo').value).to eq('')

    click_button 'X'

    expect(page).to_not have_content('Todo 1')

    # Make sure it deleted
    page.driver.browser.navigate.refresh
    expect(page).to_not have_content('Todo 1')
  end
end
