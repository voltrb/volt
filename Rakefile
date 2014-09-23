require 'rubygems'
require 'bundler'
require "bundler/gem_tasks"
require 'opal/rspec/rake_task'
Bundler.require(:development)
Opal.append_path(File.expand_path('../lib', __FILE__))

Opal::RSpec::RakeTask.new

task default: [:test]

task :test do
  system 'bundle exec rspec spec'
  Rake::Task['opal:rspec'].invoke
end

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