require 'spec_helper'

describe "missing tags and view's", type: :feature do
  it 'should show a message about the missing tag/view' do
    visit '/missing'

    expect(page).to have_content('view or tag at "some/wrong/path"')
    expect(page).to have_content('view or tag at "not/a/component"')
  end
end
