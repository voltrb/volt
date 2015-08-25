require 'spec_helper'

if ENV['BROWSER'] && ENV['BROWSER'] == 'phantom'
  describe 'Rack Requests', type: :feature do
    it 'should send JS file with JS mimetype' do
      visit '/app/components/main.js'

      expect(page.response_headers['Content-Type']).to include 'application/javascript'
    end
  end
end
