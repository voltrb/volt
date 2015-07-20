require 'volt/server/component_templates'
require 'opal/sprockets/processor'
require 'sprockets'
require 'tilt'
require 'opal/sprockets/processor'

module Volt



  class ViewProcessor < ::Opal::TiltTemplate

    def initialize(client)
      @client = client
    end

    def app_reference
      if @client
        'Volt.current_app'
      else
        'volt_app'
      end
    end

    def cache_key
      @cache_key ||= "#{self.class.name}:0.1".freeze
    end

    # def evaluate(context, locals, &block)
    #   binding.pry
    #   @data = compile(@data)
    #   super
    # end

    def call(input)
      # pp input
      data = input[:data]

      # input[:accept] = 'application/javascript'
      # input[:content_type] = 'application/javascript'
      # input[:environment].content_type = 'application/javascript'
      input[:cache].fetch([self.cache_key, data]) do
        filename = input[:filename]
        # puts input[:data].inspect
        # Remove all semicolons from source
        # input[:content_type] = 'application/javascript'
        compile(filename, input[:data])
      end
    end

    def compile(view_path, html)
      exts = ComponentTemplates::Preprocessors.extensions
      template_path = view_path.split('/')[-4..-1].join('/').gsub('/views/', '/').gsub(/[.](#{exts.join('|')})$/, '')

      exts = ComponentTemplates::Preprocessors.extensions

      format = File.extname(view_path).downcase.delete('.').to_sym
      code = ''

      # Process template if we have a handler for this file type
      if handler = ComponentTemplates.handler_for_extension(format)
        html = handler.call(html)

        code = ViewParser.new(html, template_path).code(app_reference)
      end

      Opal.compile(code)
    end

    def self.setup
      sprockets = $volt_app.sprockets
      sprockets.register_mime_type 'application/vtemplate', extensions: ['.html', '.email']
      sprockets.register_transformer 'application/vtemplate', 'application/javascript', Volt::ViewProcessor.new(true)
    end
  end
end

