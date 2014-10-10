# ComponentPaths gives an array of every folder where you find a component.
class ComponentPaths
  def initialize(root=nil)
    @root = root || Dir.pwd
  end

  # Yield for every folder where we might find components
  def app_folders
    # Find all app folders
    @app_folders ||= begin
      volt_app = File.expand_path(File.join(File.dirname(__FILE__), "../../../../app"))
      app_folders = [volt_app, "#{@root}/app", "#{@root}/vendor/app"].map {|f| File.expand_path(f) }

      # Gem folders with volt in them
      # TODO: we should probably qualify this a bit more
      app_folders += Gem.loaded_specs.values.map { |g| g.full_gem_path }.reject {|g| g !~ /volt/ }.map {|f| f + '/app' }

      app_folders
    end

    # Yield each app folder and return a flattened array with
    # the results

    files = []
    @app_folders.each do |app_folder|
      files << yield(app_folder)
    end

    return files.flatten
  end

  # returns an array of every folder that is a component
  def components
    return @components if @components

    @components = {}
    app_folders do |app_folder|
      Dir["#{app_folder}/*"].sort.each do |folder|
        if File.directory?(folder)
          folder_name = folder[/[^\/]+$/]

          @components[folder_name] ||= []
          @components[folder_name] << folder
        end
      end
    end

    return @components
  end

  # Makes each components classes available on the load path, require classes.
  def require_in_components
    if RUBY_PLATFORM == 'opal'
    else
      app_folders do |app_folder|
        $LOAD_PATH.unshift(app_folder)

        # Sort so we get consistent load order across platforms
        Dir["#{app_folder}/*/{controllers,models,tasks}/*.rb"].each do |ruby_file|
          path = ruby_file.gsub(/^#{app_folder}\//, '')[0..-4]
          require(path)
        end

        if Volt.server?
          # Add models to page
          Dir["#{app_folder}/*/models/*.rb"].each do |ruby_file|
            class_name = File.basename(ruby_file).gsub(/[.]rb$/, '')
            $page.add_model(class_name)
          end
        end
      end
    end
  end

  # Returns the path for a specific component
  def component_path(name)
    folders = components[name]

    if folders
      return folders.first
    else
      return nil
    end
  end

  # Return every asset folder we need to serve from
  def asset_folders
    folders = []
    app_folders do |app_folder|
      Dir["#{app_folder}/*/assets"].sort.each do |asset_folder|
        folders << yield(asset_folder)
      end
    end

    folders.flatten
  end

end
