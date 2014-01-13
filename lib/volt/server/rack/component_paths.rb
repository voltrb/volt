class ComponentPaths
  def initialize(root=nil)
    @root = root || Dir.pwd
  end
  
  # Yield for every folder where we might find components
  def app_folders
    # Find all app folders
    @app_folders ||= begin
      app_folders = ["#{@root}/app", "#{@root}/vendor/app"].map {|f| File.expand_path(f) }
      
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
  
  def components
    return @components if @components
    
    @components = {}
    app_folders do |app_folder|
      Dir["#{app_folder}/*"].each do |folder|
        if File.directory?(folder)
          folder_name = folder[/[^\/]+$/]
          
          @components[folder_name] ||= []
          @components[folder_name] << folder
        end
      end
    end
    
    return @components
  end
  
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
      Dir["#{app_folder}/*/assets"].each do |asset_folder|
        folders << yield(asset_folder)
      end
    end
    
    folders.flatten
  end

end