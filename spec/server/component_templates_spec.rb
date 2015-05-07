if RUBY_PLATFORM == 'opal'
else
  require 'spec_helper'
  require 'benchmark'
  require 'volt/server/component_templates'

  describe Volt::ComponentTemplates do
    let(:ct_haml){ Volt::ComponentTemplates.new('path/to/things.haml', 'thing') }
    
    before :each do
      # Register new handler
      ct_haml
      Volt::ComponentTemplates.register_template_handler(:haml, double(:haml_handler)) 
    end

    it 'can be extended' do
      expect( Volt::ComponentTemplates::Handlers.extensions ).to eq([ :html, :email, :haml ])

      expect( ct_haml.generate_view_code ).to eq("")
    end
  end

end
