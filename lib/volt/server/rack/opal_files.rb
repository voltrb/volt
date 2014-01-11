SOURCE_MAPS = !!ENV['MAPS']

Opal::Processor.source_map_enabled = SOURCE_MAPS
# Opal::Processor.arity_check_enabled = true
# Opal::Processor.dynamic_require_severity = :raise

# Sets up the maps for the opal assets, and source maps if enabled.
class OpalFiles
  def initialize(builder, app_path, asset_files)
    @asset_files = asset_files
    environment = Opal::Environment.new
  
    environment.append_path(app_path)
  
    volt_gem_lib_path = File.expand_path(File.join(File.dirname(__FILE__), "../../.."))
    environment.append_path(volt_gem_lib_path)

    add_asset_folders(environment)

    # Add the opal load paths
    Opal.paths.each do |path|
      environment.append_path(path)
    end

    # opal-jquery gem
    spec = Gem::Specification.find_by_name("opal-jquery")
    environment.append_path(spec.gem_dir + "/opal")

    builder.map '/assets' do
      run environment
    end

    if SOURCE_MAPS
      source_maps = SourceMapServer.new(environment)

      builder.map(source_maps.prefix) do
        run source_maps
      end
    end    
  end
  
  def add_asset_folders(environment)
    @asset_files.asset_folders.each do |asset_folder|
      environment.append_path(asset_folder)
    end
  end
  
end