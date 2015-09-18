require 'volt/server/template_handlers/view_processor'
require 'sprockets'

# This file Monkeypatches sprockets to provide custom file loading (from volt
# instead disk) for component root files.  These files then require in all parts
# or include generated ruby for templates, routes, and tasks.
module Volt
  class StatStub
    def directory?
      false
    end

    def file?
      false
    end

    def stub?
      true
    end

    def digest
      "stub-digest-#{mtime}"
    end

    # Get the mtime from the forking server
    def mtime
      Volt::Dispatcher.component_last_modified_time.to_s
    end
  end
end

module Sprockets
  # Internal: The first processor in the pipeline that reads the file into
  # memory and passes it along as `input[:data]`.
  class FileReader
    def self.call(input)
      env = input[:environment]
      path = input[:filename]

      # Handle a /components path match.  /components will load up a component.
      if path =~ /\/components\/[^.]+[.]rb$/
        component_name = path.match(/\/components\/([^.]+)[.]rb$/)[1]

        cached = env.cached

        stats = cached.instance_variable_get('@stats')

        stats[path] = Volt::StatStub.new

        # Working with a component path
        volt_app = Thread.current['volt_app'] || $volt_app
        data = Volt::ComponentCode.new(volt_app, component_name, volt_app.component_paths, true).code
      else
        data = env.read_file(input[:filename], input[:content_type])
      end

      # dependencies = Set.new(input[:metadata][:dependencies])
      # dependencies += [env.build_file_digest_uri(input[:filename])]

      dependencies = input[:metadata][:dependencies]
      # dependencies.merge(env.build_file_digest_uri(input[:filename]))

      { data: data, dependencies: dependencies }
    end
  end
end

module Sprockets
  # Internal: File and path related utilities. Mixed into Environment.
  #
  # Probably would be called FileUtils, but that causes namespace annoyances
  # when code actually wants to reference ::FileUtils.
  module PathUtils
    extend self

    # Public: Like `File.file?`.
    #
    # path - String file path.
    #
    # Returns true path exists and is a file.
    def file?(path)
      if stat = self.stat(path)
        stat.file?
      elsif path =~ /^#{Volt.root}\/app\/components\/[^\/]+[.]rb$/
        # Matches a component
        return true
      else
        false
      end
    end
  end
end

module Sprockets
  module PathDigestUtils
    def stat_digest(path, stat)
      if stat.directory?
        # If its a directive, digest the list of filenames
        digest_class.digest(self.entries(path).join(','))
      elsif stat.file?
        # If its a file, digest the contents
        digest_class.file(path.to_s).digest
      elsif stat.stub?
        # Component lookup, custom digest that always invalidates
        return stat.digest
      else
        raise TypeError, "stat was not a directory or file: #{stat.ftype}"
      end
    end
  end
end

module Sprockets
  class Base
    def file_digest(path)
      if stat = self.stat(path)
        # Caveat: Digests are cached by the path's current mtime. Its possible
        # for a files contents to have changed and its mtime to have been
        # negligently reset thus appearing as if the file hasn't changed on
        # disk. Also, the mtime is only read to the nearest second. Its
        # also possible the file was updated more than once in a given second.
        cache.fetch("file_digest:#{path}:#{stat.mtime.to_i}") do
          self.stat_digest(path, stat)
        end
      elsif path =~ /^#{Volt.root}\/app\/components\/[^\/]+$/
        # Return a random mtime
        # puts "LMT: #{Volt::Dispatcher.last_modified_time.inspect}"
        mtime = Volt::Dispatcher.component_last_modified_time.to_s

        # puts "STUB: #{mtime}"
        "stub-digest-#{mtime}"
      end
    end
  end
end

module Sprockets
  module Resolve
    def path_matches(load_path, logical_name, logical_basename)

      dirname    = File.dirname(File.join(load_path, logical_name))
      candidates = dirname_matches(dirname, logical_basename)
      deps       = file_digest_dependency_set(dirname)

      if load_path == "#{Volt.root}/app"
        match = logical_name.match(/^components\/([^\/]+)$/)
        if match && (component_name = match[1])
          return [["#{Volt.root}/app/components/#{component_name}.rb", "application/javascript"]], deps
        end
      end

      result = resolve_alternates(load_path, logical_name)
      result[0].each do |fn|
        candidates << [fn, parse_path_extnames(fn)[1]]
      end
      deps.merge(result[1])

      dirname = File.join(load_path, logical_name)
      if directory? dirname
        result = dirname_matches(dirname, "index")
        candidates.concat(result)
      end

      deps.merge(file_digest_dependency_set(dirname))

      return candidates.select { |fn, _| file?(fn) }, deps
    end
  end
end
