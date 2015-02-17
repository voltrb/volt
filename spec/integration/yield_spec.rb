if ENV['BROWSER']
  require 'spec_helper'

  describe 'yield binding', type: :feature, sauce: true do
    before do
      visit '/yield'
    end

    it 'should render the yielded content multiple times' do
      expect(page).to have_content("My yielded content 1")
      expect(page).to have_content("My yielded content 2")
    end

    it 'should render the content from the tag\'s controller when yielding' do
      expect(page).to have_content('This is my content')
    end
  end
end