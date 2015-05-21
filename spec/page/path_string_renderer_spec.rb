require 'spec_helper'
require 'volt/page/path_string_renderer'

unless RUBY_PLATFORM == 'opal'
  describe Volt::PathStringRenderer do
    before do
      kitchen_sink_path = File.expand_path(File.join(File.dirname(__FILE__), '../apps/kitchen_sink'))
      @volt_app = Volt::App.new(kitchen_sink_path)
      @page = @volt_app.page
    end

    it 'should render a section' do
      html = Volt::PathStringRenderer.new(@volt_app, 'main/mailers/welcome/subject', nil, @page).html
      expect(html).to eq("\n  Welcome to the site!\n\n")
    end

    it 'should render a section with a variable' do
      html = Volt::PathStringRenderer.new(@volt_app, 'main/mailers/welcome/html', { name: 'Jimmy' }, @page).html
      expect(html).to eq("\n  <h1>Welcome Jimmy</h1>\n\n  <p>Glad you signed up!</p>\n\n")
    end

    it 'Raises raises ViewLookupException if full_path is nil' do
      expect do
        Volt::PathStringRenderer.new(@volt_app, '', { name: 'Jimmy' }, Volt::Page.new(@volt_app)).html
      end.to raise_error(Volt::ViewLookupException)
    end
  end
end
