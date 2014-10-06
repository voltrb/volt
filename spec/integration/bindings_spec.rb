if ENV['BROWSER']
  require 'spec_helper'

  describe "bindings test", :type => :feature do
    it "should load the page" do
      visit '/'

      expect(page).to have_content('Kitchen Sink')
    end

    describe "text/fields" do
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

      it 'should go from a url and query to params' do
        visit '/bindings/testing?name=cool'

        expect(find('#paramsName3')).to have_content('cool')
        expect(find('#routesName3')).to have_content('testing')
      end

      it 'should load the bindings page and update bindings' do
        visit '/'

        click_link 'Bindings'

        # Fill in one field and see if it updates the rest
        fill_in('textareaName1', :with => 'Page bindings')
        expect(find('#textareaName1').value).to eq('Page bindings')
        expect(find('#textareaName2').value).to eq('Page bindings')
        expect(find('#textareaName3')).to have_content('Page bindings')

        fill_in('textareaName2', :with => 'Update everywhere')
        expect(find('#textareaName1').value).to eq('Update everywhere')
        expect(find('#textareaName2').value).to eq('Update everywhere')
        expect(find('#textareaName3')).to have_content('Update everywhere')
      end

      it 'should update local_store bindings' do
        visit '/'

        click_link 'Bindings'

        # Fill in one field and see if it updates the rest
        fill_in('localstoreName1', :with => 'Page bindings')
        expect(find('#localstoreName1').value).to eq('Page bindings')
        expect(find('#localstoreName2').value).to eq('Page bindings')
        expect(find('#localstoreName3')).to have_content('Page bindings')

        fill_in('localstoreName2', :with => 'Update everywhere')
        expect(find('#localstoreName1').value).to eq('Update everywhere')
        expect(find('#localstoreName2').value).to eq('Update everywhere')
        expect(find('#localstoreName3')).to have_content('Update everywhere')
      end

      # it 'should update local_store bindings' do
      #   visit '/'
      #
      #   click_link 'Bindings'
      #
      #   within '#pageSelect1' do
      #     find("option[value='two']").click
      #   end
      #
      #   # Fill in one field and see if it updates the rest
      #   expect(find('#pageSelect1').value).to eq('two')
      #   expect(find('#pageSelect2').value).to eq('two')
      #   expect(find('#pageSelect3')).to have_content('two')
      #
      #   # Fill in one field and see if it updates the rest
      #   fill_in('pageSelect2', :with => 'three')
      #   expect(find('#pageSelect1').value).to eq('three')
      #   expect(find('#pageSelect2').value).to eq('three')
      #   expect(find('#pageSelect3')).to have_content('three')
      # end
    end

    describe "check boxes" do
      it 'should load the bindings page and update checkboxes' do
        visit '/'

        click_link 'Bindings'

        expect(find('#pageCheck3')).to have_content('')
        # Fill in one field and see if it updates the rest
        check('pageCheck1')
        expect(find('#pageCheck1')).to be_checked
        expect(find('#pageCheck2')).to be_checked
        expect(find('#pageCheck3')).to have_content('true')

        uncheck('pageCheck1')
        expect(find('#pageCheck1')).to_not be_checked
        expect(find('#pageCheck2')).to_not be_checked
        expect(find('#pageCheck3')).to have_content('')
      end

      it 'should load the bindings page and update checkboxes bound to params' do
        visit '/'

        click_link 'Bindings'

        if ENV['BROWSER'] != 'phantom'
          expect(current_path).to eq('/bindings')
        end

        expect(find('#paramsCheck3')).to have_content('')
        # Fill in one field and see if it updates the rest
        check('paramsCheck1')
        expect(find('#paramsCheck1')).to be_checked
        expect(find('#paramsCheck2')).to be_checked
        expect(find('#paramsCheck3')).to have_content('true')

        if ENV['BROWSER'] != 'phantom'
          expect(current_url).to match(/\/bindings[?]check[=]true$/)
        end

        uncheck('paramsCheck1')
        expect(find('#paramsCheck1')).to_not be_checked
        expect(find('#paramsCheck2')).to_not be_checked
        expect(find('#paramsCheck3')).to have_content('')

        if ENV['BROWSER'] != 'phantom'
          expect(current_url).to match(/\/bindings[?]check[=]false$/)
        end
      end
    end

    describe "content escaping" do
      it 'should escape in a tripple stash' do
        visit '/'

        click_link 'Bindings'

        expect(find('#escapeContent')).to have_content('this is {{escaped}}')
      end
    end
  end
end
