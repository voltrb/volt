require 'uri'

# Used to get a list of the assets and other included components
# from the dependencies.rb files.
module Volt
  class AssetFiles
    def self.from_cache(app_url, component_name, component_paths)
      # @cache ||= {}

      # @cache[component_name] ||= begin
        # not cached, create

        self.new(app_url, component_name, component_paths)
      # end
    end

    def initialize(app_url, component_name, component_paths)
      @app_url = app_url
      @component_paths     = component_paths
      @assets              = []
      @included_components = {}
      @components          = []
      @disable_auto_import = []

      # Include each of the default included components
      Volt.config.default_components.each do |def_comp_name|
        component(def_comp_name)
      end

      component(component_name)
    end

    def disable_auto_import
      @disable_auto_import.push(*@current_component).uniq
    end

    def load_dependencies(path, component_name)
      if path
        dependencies_file = File.join(path, 'config/dependencies.rb')
      else
        fail "Unable to find component #{component_name.inspect}"
      end

      if File.exist?(dependencies_file)
        # Run the dependencies file in this asset files context
        code = File.read(dependencies_file)
        @current_component = component_name
        instance_eval(code, dependencies_file, 0)
      end
    end

    def component(name)
      unless @included_components[name]
        # Track that we added
        @included_components[name] = true

        # Get the path to the component
        component_path = @component_paths.component_paths(name)

        unless component_path
          fail "Unable to find component '#{name}', make sure the gem is included in your Gemfile"
        end

        component_path.each do |path|
          # Load the dependencies
          load_dependencies(path, name)

          # Add any assets
          add_assets(path) unless @disable_auto_import.include?(name)
          @components << [path, name]
        end
      end
    end

    # Called when you want to add a gem to the opal load path so it can be
    # required on the client side.
    def opal_gem(gem_name)
      Opal.use_gem(gem_name)
      Opal.paths.uniq!
      # require(gem_name)
    end

    def components
      @included_components.keys
    end

    def javascript_file(locator)
      @assets << [:javascript_file, prepare_locator(locator, ['js'])]
    end

    def css_file(locator)
      @assets << [:css_file, prepare_locator(locator, ['css','scss','sass'])]
    end

    def prepare_locator(locator, valid_extensions)
      unless url_or_path?(locator)
        locator = File.join(@app_url, @current_component, '/assets', valid_extensions.first, "#{locator}")
        locator += '.css' unless locator =~ /^.*\.(#{valid_extensions.join('|')})$/
      end
      locator
    end

    def url_or_path?(url)
      (url =~ URI::regexp || url =~ /^\/(\/)?.*/) ? true : false
    end

    def component_paths
      @components
    end

    def add_assets(path)
      asset_folder = File.join(path, 'assets')
      @assets << [:folder, asset_folder] if File.directory?(asset_folder)
    end

    def javascript_files(*args)
      fail "Deprecation: #javascript_files is deprecated in config/base/index.html, opal 0.8 required a new format.  For an updated config/base/index.html file, see https://gist.github.com/ryanstout/0858cf7dfc32c514f790"
    end

    def css_files(*args)
      fail "Deprecation: #css_files is deprecated in config/base/index.html, opal 0.8 required a new format.  For an updated config/base/index.html file, see https://gist.github.com/ryanstout/0858cf7dfc32c514f790"
    end

    # Returns script tags that should be included
    def javascript_tags(volt_app)
      @opal_tag_generator ||= Opal::Server::Index.new(nil, volt_app.opal_files.server)

      javascript_files = []
      @assets.each do |type, path|
        case type
          when :folder
            # for a folder, we search for all .js files and return a tag for them
            base_path = base(path)
            javascript_files += Dir["#{path}/**/*.js"].sort.map do |folder|
              # Grab the component folder/assets/js/file.js
              local_path = folder[path.size..-1]
              @app_url + '/' + base_path + local_path
            end
          when :javascript_file
            # javascript_file is a cdn path to a JS file
            javascript_files << path
        end
      end

      javascript_files = javascript_files.uniq

      scripts = javascript_files.map {|url| "<script src=\"#{url}\"></script>" }

      # Include volt itself.  Unless we are running with MAPS=all, just include
      # the main file without sourcemaps.
      volt_path = 'volt/volt/app'
      if ENV['MAPS'] == 'all'
        scripts << @opal_tag_generator.javascript_include_tag(volt_path)
      else
        scripts << "<script src=\"#{volt_app.app_url}/#{volt_path}.js\"></script>"
        scripts << "<script>#{Opal::Processor.load_asset_code(volt_app.sprockets, volt_path)}</script>"
      end

      scripts << @opal_tag_generator.javascript_include_tag('components/main')

      scripts.join("\n")
    end

    # Returns the link tags for the css
    def css_tags
      css.map do |url|
        "<link href=\"#{url}\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />"
      end.join("\n")
    end

    # Returns an array of all css files that should be included.
    def css
      css_files = []
      @assets.each do |type, path|
        case type
          when :folder
            # Don't import any css/scss files that start with an underscore, so scss partials
            # aren't imported by default:
            #  http://sass-lang.com/guide
            base_path = base(path)
            css_files += Dir["#{path}/**/[^_]*.{css,scss,sass}"].sort.map do |folder|
              local_path = folder[path.size..-1].gsub(/[.](scss|sass)$/, '')
              css_path = @app_url + '/' + base_path + local_path
              css_path += '.css' unless css_path =~ /[.]css$/
              css_path
            end
          when :css_file
            css_files << path
        end
      end

      css_files.uniq
    end

    # #javascript is only used on the server
    unless RUBY_PLATFORM == 'opal'
      # Parses the javascript tags to reutrn the following:
      # [[:src, '/somefile.js'], [:body, 'var inlinejs = true;']]
      def javascript(volt_app)
        javascript_tags(volt_app)
        .scan(/[<]script([^>]*)[>](.*?)[<]\/script[^>]*[>]/m)
        .map do |attrs, body|
          src = attrs.match(/[\s|$]src\s*[=]\s*["']([^"']+?)["']/)

          if src
            [:src, src[1]]
          else
            [:body, body]
          end
        end
      end
    end

    private
    def base(path)
      path.split('/')[-2..-1].join('/')
    end


  end
end
