if RUBY_PLATFORM == 'opal'
else
  require 'spec_helper'
  require 'benchmark'
  require 'volt/server/component_templates'
end

describe Volt::ComponentTemplates do
  let(:ct){ Volt::ComponentTemplates.new('path/to/things', 'thing') }

  describe "#available_formats" do
    let(:ct_haml){ Volt::ComponentTemplates.new('path/to/things.haml', 'thing') }
    it 'can be extended' do
      # Register new handler
      Volt::ComponentTemplates.register_template_handler(:haml, double(:haml_handler))  

      expect( Volt::ComponentTemplates::Handlers.extensions ).to eq([ :html, :email, :haml ])

      expect( ct_haml.generate_view_code ).to eq("")
    end
  end
end