require 'bundler'
require 'bundler/gem_tasks'
Bundler.require(:development)
require 'rubocop/rake_task'
require 'opal'

# Add our opal/ directory to the load path
Opal.append_path(File.expand_path('../lib', __FILE__))

require 'opal/rspec/rake_task'

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

# Setup the opal:rspec task
Opal::RSpec::RakeTask.new('opal:rspec') do |s|
  # Add the app folder to the opal load path.
  s.append_path('app')
end


task default: [:test]

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('ruby:rspec')

task :test do
  puts "--------------------------\nRun specs in Opal\n--------------------------"
  Rake::Task['opal:rspec'].invoke
  puts "--------------------------\nRun specs in normal ruby\n--------------------------"
  Rake::Task['ruby:rspec'].invoke
end

# Rubocop task
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--display-cop-names']
end
