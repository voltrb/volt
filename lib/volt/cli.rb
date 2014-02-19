require 'bundler/setup'
require 'thor'

class CLI < Thor
  include Thor::Actions

  desc "new PROJECT_NAME", "generates a new project."
  def new(name)
    # Grab the current volt version
    version = File.read(File.join(File.dirname(__FILE__), '../../VERSION'))
    directory("project", name, {version: version, name: name})

    say "Bundling Gems...."
    `cd #{name} ; bundle -j 4`
  end

  desc "console", "run the console on the project in the current directory"
  def console
    require 'volt/console'
    Console.start
  end

  desc "server", "run the server on the project in the current directory"
  method_option :port, :type => :string, :aliases => '-p', :banner => 'specify which port the server should run on'
  def server
    require 'thin'
    require 'fileutils'

    # If we're in a Volt project, clear the temp directory
    # TODO: this is a work around for a bug when switching between
    # source maps and non-source maps.
    if File.exists?("config.ru") && File.exists?("Gemfile")
      FileUtils.rm_rf("tmp/.")
    else
      say("Current folder is not a Volt project", :red)
      return
    end

    ENV['SERVER'] = 'true'
    args = ['start', '--threaded', '--max-persistent-conns', '300', "--max-conns", "400"]

    if options[:port]
      args += ['-p', options[:port].to_s]
    end

    Thin::Runner.new(args).run!

    # require 'volt/server'
    #
    # EM.run do
    #   thin = Rack::Handler.get("thin")
    #   thin.run(Server.new.app, Port: 3000)
    # end
  end

  desc "gem GEM", "Creates a component gem where you can share a component"
  method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :banner => "Generate a binary for your library."
  method_option :test, :type => :string, :lazy_default => 'rspec', :aliases => '-t', :banner => "Generate a test directory for your library: 'rspec' is the default, but 'minitest' is also supported."
  method_option :edit, :type => :string, :aliases => "-e",
                :lazy_default => [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? },
                :required => false, :banner => "/path/to/your/editor",
                :desc => "Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)"
  def gem(name)
    require 'volt/cli/new_gem'

    NewGem.new(self, name, options)
  end

  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), '../../templates'))
  end
end


puts "Volt #{File.read(File.join(File.dirname(__FILE__), "../../VERSION"))}"
CLI.start(ARGV)
