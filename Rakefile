require 'rubygems'
require 'bundler'
require "bundler/gem_tasks"
Bundler.require(:development)


task :docs do
  `bundle exec yardoc 'lib/**/*.rb' - Readme.md docs/*`
  # require 'yard'
  # require 'yard-docco'
  #
  # YARD::Rake::YardocTask.new do |t|
  #   t.files   = ['lib/**/*.rb']
  #   # t.options = ['--any', '--extra', '--opts'] # optional
  # end
end


require 'opal'
# Add our opal/ directory to the load path
Opal.append_path(File.expand_path('../lib', __FILE__))

require 'opal/rspec/rake_task'
Opal::RSpec::RakeTask.new(:default)