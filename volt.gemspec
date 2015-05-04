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
  spec.add_dependency 'pry', '~> 0.10.1'
  spec.add_dependency 'rack', '~> 1.5'
  spec.add_dependency 'sprockets-sass', '~> 1.0.0'
  spec.add_dependency 'sass', '~> 3.2.5'
  spec.add_dependency 'mongo', '~> 1.9.0'
  spec.add_dependency 'listen', '~> 2.8.0'
  spec.add_dependency 'uglifier', '>= 2.4.0'
  spec.add_dependency "configurations", "~> 2.0.0.pre"
  spec.add_dependency 'yui-compressor', '~> 0.12.0'
  spec.add_dependency 'opal', '~> 0.7.2'
  spec.add_dependency 'bundler', '>= 1.5'
  spec.add_dependency 'faye-websocket', '~> 0.9.2'
  spec.add_dependency 'concurrent-ruby', '~> 0.8.0'

  # For user passwords
  spec.add_dependency 'bcrypt', '~> 3.1.9'

  # For testing
  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'opal-rspec', '~> 0.4.2'
  spec.add_development_dependency 'capybara', '~> 2.4.2'
  spec.add_development_dependency 'selenium-webdriver', '~> 2.43.0'
  spec.add_development_dependency 'chromedriver2-helper', '~> 0.0.8'
  spec.add_development_dependency 'poltergeist', '~> 1.5.0'
  # spec.add_development_dependency 'puma', '~> 2.11.2'
  spec.add_development_dependency 'thin', '~> 1.6.3'
  spec.add_development_dependency 'coveralls', '~> 0.8.1'

  spec.add_development_dependency 'guard', '2.6.0' # bug in current guard
  spec.add_development_dependency 'guard-rspec', '~> 4.3.0'
  spec.add_development_dependency 'rake', '~> 10.0.4'

  # Yard and formatting
  spec.add_development_dependency 'yard', '~> 0.8.7.0'
  spec.add_development_dependency 'redcarpet', '~> 3.2.2'
  spec.add_development_dependency 'github-markup', '~> 1.3.1'

  spec.add_development_dependency 'sauce', '~> 3.5.3'
  spec.add_development_dependency 'sauce-connect', '~> 3.5.0'
  spec.add_development_dependency 'pry-byebug', '~> 2.0.0'
end
