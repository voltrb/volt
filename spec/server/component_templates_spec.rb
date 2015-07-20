if RUBY_PLATFORM == 'opal'
else
  require 'spec_helper'
  require 'benchmark'
  require 'volt/server/component_templates'

  describe Volt::ComponentTemplates do
    let(:haml_handler) do
      double(:haml_handler)
    end

    it 'can be extended' do
      expect( Volt::ComponentTemplates::Preprocessors.extensions ).to eq([ :html, :email ])

      Volt::ComponentTemplates.register_template_handler(:haml, haml_handler)

      expect( Volt::ComponentTemplates::Preprocessors.extensions ).to eq([ :html, :email, :haml ])
    end
  end

end
