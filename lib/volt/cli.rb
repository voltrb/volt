require 'bundler/setup'
require 'thor'

class CLI < Thor
  include Thor::Actions
  
  desc "new PROJECT_NAME", "generates a new project."
  def new(name)
    directory(".", name)
    
    say "Bundling Gems...."
    `cd #{name} ; bundle`
  end
  
  desc "console", "run the console on the project in the current directory"
  def console
    require 'volt/console'
    Console.start
  end

  desc "server", "run the server on the project in the current directory"
  def server
    require 'thin'

    ENV['SERVER'] = 'true'
    Thin::Runner.new(['start']).run!
  end
  
  def self.source_root
    File.expand_path(File.join(File.dirname(__FILE__), '../../templates'))
  end
end

CLI.start(ARGV)