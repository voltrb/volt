require 'volt/server/component_templates'
require 'opal/sprockets/processor'
require 'sprockets'
require 'tilt'
require 'opal/sprockets/processor'
require 'sprockets/uri_utils'

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
      @cache_key ||= "#{self.class.name}:0.2".freeze
    end

    # def evaluate(context, locals, &block)
    #   binding.pry
    #   @data = compile(@data)
    #   super
    # end

    def call(input)
      context = input[:environment].context_class.new(input)
      # context.link_asset('main/assets/images/lombard.jpg')
      # puts context.asset_path('main/assets/images/lombard.jpg').inspect
      # pp input
      data = input[:data]

      # input[:accept] = 'application/javascript'
      # input[:content_type] = 'application/javascript'
      # input[:environment].content_type = 'application/javascript'
      compiled = false
      data, links = input[:cache].fetch([self.cache_key, data]) do
        compiled = true
        filename = input[:filename]
        # puts input[:data].inspect
        # Remove all semicolons from source
        # input[:content_type] = 'application/javascript'

        # Track the dependency
        context.metadata[:dependencies] << Sprockets::URIUtils.build_file_digest_uri(input[:filename])

        compile(filename, input[:data], context)
      end

      unless compiled
        links.each do |link|
          context.link_asset(link)
        end
      end

      context.metadata.merge(data: data.to_str)
    end

    def compile(view_path, html, context)
      exts = ComponentTemplates::Preprocessors.extensions
      template_path = view_path.split('/')[-4..-1].join('/').gsub('/views/', '/').gsub(/[.](#{exts.join('|')})$/, '')

      format = File.extname(view_path).downcase.delete('.').to_sym
      code = ''

      # Process template if we have a handler for this file type
      if handler = ComponentTemplates.handler_for_extension(format)
        html = handler.call(html)

        parser = ViewParser.new(html, template_path, context)
        code = parser.code(app_reference)
      end

      return [Opal.compile(code), parser.links]
    end

    def self.setup(sprockets=$volt_app.sprockets)
      exts = ComponentTemplates::Preprocessors.extensions.map{ |ext| ".#{ext}" }

      sprockets.register_mime_type 'application/vtemplate', extensions: exts
      sprockets.register_transformer 'application/vtemplate', 'application/javascript', Volt::ViewProcessor.new(true)
    end
  end
end
