if ENV['BROWSER'] == 'firefox'
  require 'spec_helper'

  describe "todo example spec", :type => :feature do
    before do
      visit '/'

      click_link 'Todos'


      fill_in('newtodo', :with => "Item 1\n")
      fill_in('newtodo', :with => "Item 2\n")
      fill_in('newtodo', :with => "Item 3\n")
    end

    it "should add items to the list" do
      expect(find('#todos-table')).to have_content('Item 1')
    end

    it 'should strikethrough when the checkbox is checked' do
      box = all(:css, "#todos-table input[type=checkbox]")[0]

      expect(find('#todos-table')).to_not have_css('td.name.complete')

      box.set(true)
      expect(find('#todos-table')).to have_css('td.name.complete')

      box.set(false)
      expect(find('#todos-table')).to_not have_css('td.name.complete')
    end

    it 'should delete items' do
      expect(find('#todos-table')).to have_content('Item 1')
      expect(find('#todos-table')).to have_content('Item 2')
      expect(find('#todos-table')).to have_content('Item 3')

      # Click the middle one
      all(:css, "#todos-table button")[1].click

      expect(find('#todos-table')).to have_content('Item 1')
      expect(find('#todos-table')).to_not have_content('Item 2')
      expect(find('#todos-table')).to have_content('Item 3')
    end
  end
end