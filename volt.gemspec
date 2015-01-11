# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'volt'
  spec.version       = version
  spec.authors       = ['Ryan Stout']
  spec.email         = ['ryan@agileproductions.com']
  spec.summary       = 'A ruby web framework where your ruby runs on both server and client (via Opal)'
  # spec.description   = %q{}
  spec.homepage      = 'http://voltframework.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.19.0'
  spec.add_dependency 'pry', '~> 0.10.0'
  spec.add_dependency 'rack', '~> 1.5.0'
  spec.add_dependency 'sprockets-sass', '~> 1.0.0'
  spec.add_dependency 'sass', '~> 3.2.5'
  spec.add_dependency 'mongo', '~> 1.9.0'
  spec.add_dependency 'rake', '~> 10.0.4'
  spec.add_dependency 'listen', '~> 2.8.0'
  spec.add_dependency 'uglifier', '>= 2.4.0'
  spec.add_dependency 'configurations', '~> 2.0.0.pre'
  spec.add_dependency 'yui-compressor', '>= 0.12.0'
  spec.add_dependency 'opal', '~> 0.6.0'
  spec.add_dependency 'opal-jquery', '~> 0.2.0'
  spec.add_dependency 'rspec-core', '~> 3.1.0'
  spec.add_dependency 'rspec-expectations', '~> 3.1.0'
  spec.add_dependency 'capybara', '~> 2.4.2'
  spec.add_dependency 'selenium-webdriver', '~> 2.43.0'
  spec.add_dependency 'chromedriver2-helper', '~> 0.0.8'
  spec.add_dependency 'poltergeist', '~> 1.5.0'
  spec.add_dependency 'opal-rspec', '0.3.0.beta3'
  spec.add_dependency 'bundler', '>= 1.5'
  spec.add_dependency 'volt-sockjs', '~> 0.3.4.4'

  # For user passwords
  spec.add_dependency 'bcrypt', '~> 3.1.9'

  spec.add_development_dependency 'guard', '2.6.0' # bug in current guard
  spec.add_development_dependency 'guard-rspec', '~> 4.3.0'
  spec.add_development_dependency 'yard', '~> 0.8.7.0'
  spec.add_development_dependency 'sauce', '~> 3.5.3'
  spec.add_development_dependency 'sauce-connect', '~> 3.5.0'
  spec.add_development_dependency 'pry-byebug', '~> 2.0.0'
end
