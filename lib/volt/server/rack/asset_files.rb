require 'uri'

# Used to get a list of the assets and other included components
# from the dependencies.rb files.
module Volt
  class AssetFiles
    def initialize(component_name, component_paths)
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

    def components
      @included_components.keys
    end

    def javascript_file(locator)
      @assets << [:javascript_file, prepare_locator(locator, ['js'])]
    end

    def css_file(locator)
      @assets << [:css_file, prepare_locator(locator, ['css','scss'])]
    end

    def prepare_locator(locator, valid_extensions)
      unless url_or_path?(locator)
        locator = File.join('/assets', @current_component, '/assets', valid_extensions.first, "#{locator}")
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

    def javascript_files(opal_files)
      javascript_files = []
      @assets.each do |type, path|
        case type
          when :folder
            javascript_files += Dir["#{path}/**/*.js"].sort.map { |folder| '/assets' + folder[path.size..-1] }
          when :javascript_file
            javascript_files << path
        end
      end

      opal_js_files = []
      if Volt.source_maps?
        opal_js_files += opal_files.environment['volt/volt/app'].to_a.map { |v| '/assets/' + v.logical_path + '?body=1' }
      else
        opal_js_files << '/assets/volt/volt/app.js'
      end
      opal_js_files << '/components/main.js'

      javascript_files += opal_js_files

      javascript_files.uniq
    end

    def css_files
      css_files = []
      @assets.each do |type, path|
        case type
          when :folder
            # Don't import any css/scss files that start with an underscore, so scss partials
            # aren't imported by default:
            #  http://sass-lang.com/guide
            css_files += Dir["#{path}/**/[^_]*.{css,scss}"].sort.map do |folder|
              '/assets' + folder[path.size..-1].gsub(/[.]scss$/, '')
            end
          when :css_file
            css_files << path
        end
      end

      css_files.uniq
    end
  end
end
