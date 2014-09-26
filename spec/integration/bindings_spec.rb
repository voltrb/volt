if ENV['BROWSER']
  require 'spec_helper'

  describe "bindings test", :type => :feature do
    it "should load the page" do
      visit '/'

      expect(page).to have_content('Kitchen Sink')
    end

    it 'should load the bindings page and update bindings' do
      visit '/'

      click_link 'Bindings'

      # Fill in one field and see if it updates the rest
      fill_in('pageName1', :with => 'Page bindings')
      expect(find('#pageName1').value).to eq('Page bindings')
      expect(find('#pageName2').value).to eq('Page bindings')
      expect(find('#pageName3')).to have_content('Page bindings')

      fill_in('pageName2', :with => 'Update everywhere')
      expect(find('#pageName1').value).to eq('Update everywhere')
      expect(find('#pageName2').value).to eq('Update everywhere')
      expect(find('#pageName3')).to have_content('Update everywhere')
    end

    it 'should update params bindings and the url' do
      visit '/'

      click_link 'Bindings'

      # phantom does not support the html5 history api
      # TODO: We could probably polyfill this in phantom
      if ENV['BROWSER'] != 'phantom'
        expect(current_path).to eq('/bindings')
      end

      # Fill in one field and see if it updates the rest
      fill_in('paramsName1', :with => 'Params bindings')
      expect(find('#paramsName1').value).to eq('Params bindings')
      expect(find('#paramsName2').value).to eq('Params bindings')
      expect(find('#paramsName3')).to have_content('Params bindings')

      fill_in('paramsName2', :with => 'Update everywhere')
      expect(find('#paramsName1').value).to eq('Update everywhere')
      expect(find('#paramsName2').value).to eq('Update everywhere')
      expect(find('#paramsName3')).to have_content('Update everywhere')

      if ENV['BROWSER'] != 'phantom'
        expect(current_url).to match(/\/bindings[?]name[=]Update%20everywhere$/)
      end
    end

    it 'should update the url and fields when bound to a param in the route' do
      visit '/'

      click_link 'Bindings'

      # phantom does not support the html5 history api
      # TODO: We could probably polyfill this in phantom
      if ENV['BROWSER'] != 'phantom'
        expect(current_path).to eq('/bindings')
      end

      # Fill in one field and see if it updates the rest
      fill_in('routesName1', :with => 'Routes bindings')
      expect(find('#routesName1').value).to eq('Routes bindings')
      expect(find('#routesName2').value).to eq('Routes bindings')
      expect(find('#routesName3')).to have_content('Routes bindings')

      fill_in('routesName2', :with => 'bound_url')
      expect(find('#routesName1').value).to eq('bound_url')
      expect(find('#routesName2').value).to eq('bound_url')
      expect(find('#routesName3')).to have_content('bound_url')

      if ENV['BROWSER'] != 'phantom'
        expect(current_path).to eq('/bindings/bound_url')
      end
    end
  end
end
