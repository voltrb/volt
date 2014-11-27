require 'bundler'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'
Bundler.require(:development)

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

Opal::RSpec::RakeTask.new

task default: [:test]

task :test do
  puts "--------------------------\nRun specs in normal ruby\n--------------------------"
  system 'bundle exec rspec'
  puts "--------------------------\nRun specs in Opal\n--------------------------"
  Rake::Task['opal:rspec'].invoke
end

# Rubocop task
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--display-cop-names']
end
