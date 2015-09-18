require 'spec_helper'

describe 'todos app', type: :feature, sauce: true do
  ENTER_KEY = ENV["BROWSER"] == 'phantom' ? :Enter : :return
  it 'should add a todo and remove it' do
    visit '/todos'

    fill_in 'newtodo', with: 'Todo 1'
    find('#newtodo').native.send_keys(ENTER_KEY)

    expect(page).to have_content('Todo 1')

    expect(find('#newtodo').value).to eq('')

    click_button 'X'

    expect(page).to_not have_content('Todo 1')

    # Make sure it deleted
    if ENV['BROWSER'] == 'phantom'
        visit '/todos'
    else
        page.driver.browser.navigate.refresh
    end
    expect(page).to_not have_content('Todo 1')
  end

  it 'should update a todo check state and persist' do
    visit '/todos'

    fill_in 'newtodo', with: 'Todo 1'
    find('#newtodo').native.send_keys(ENTER_KEY)

    expect(page).to have_content('Todo 1')

    find("input[type='checkbox']").click

    if ENV['BROWSER'] == 'phantom'
        visit '/todos'
    else
        page.evaluate_script('document.location.reload()')
    end

    expect(find("input[type='checkbox']").checked?).to eq(true)
  end
end