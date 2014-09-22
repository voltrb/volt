if ENV['IN_BROWSER']
  require 'spec_helper'

  describe "integration test", :type => :feature do
    it "should load the page" do
      # page.class.instance_eval do
      #   puts "DEFINE ON #{self.inspect}"
      #   define_method(:execute_script) do
      #     puts "EXEC SCRIPT"
      #   end
      # end
      
      visit '/'
      # visit 'http://devbox.com:3000/'
      
      # visit 'http://localhost:3000/'
      sleep 1
      puts "ALERT"
      page.execute_script('alert("hey");')
      sleep 3

      puts "Page: #{page.inspect}"
      
      # sleep 50
      # expect(page).to have_content('Home')
      # expect(page).to have_content('About')
      # page.has_text?('About')
      # puts "HAS CONTENT: #{page.has_text?('About')}"
    end
  end
end
