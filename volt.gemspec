lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'volt/version'

Gem::Specification.new do |spec|
  spec.name          = 'volt'
  spec.version       = Volt::Version::STRING
  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.1'
  spec.authors       = ['Ryan Stout']
  spec.email         = ['ryan@agileproductions.com']
  spec.summary       = 'A reactive Ruby web framework.'
  spec.description   = 'A reactive Ruby web framework where your Ruby code runs on both the server and the client (via Opal).'
  spec.homepage      = 'http://voltframework.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.19.0'
  spec.add_dependency 'pry', '~> 0.10.1'
  spec.add_dependency 'rack', '~> 1.5.0'
  # spec.add_dependency 'sprockets-sass', '~> 1.0.0'
  spec.add_dependency 'sass', '~> 3.4.15'
  spec.add_dependency 'listen', '~> 3.0.1'
  spec.add_dependency 'configurations', '~> 2.0.0.pre'
  spec.add_dependency 'opal', ['>= 0.8.0', '< 0.9']
  spec.add_dependency 'bundler', '>= 1.5'
  spec.add_dependency 'faye-websocket', '~> 0.10.0'
  spec.add_dependency 'sprockets-helpers', '~> 1.2.1'

  # Locking down concurrent-ruby because one currently used feature is going to
  # be deprecated (which we need to build a work around for)
  spec.add_dependency 'concurrent-ruby', '= 0.8.0'

  # For user passwords
  spec.add_dependency 'bcrypt', '~> 3.1.9'

  # For testing
  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'opal-rspec', '~> 0.4.3'
  spec.add_development_dependency 'capybara', '~> 2.4.4'

  # There is a big performance issue with selenium-webdriver on v2.45.0
  spec.add_development_dependency 'selenium-webdriver', '~> 2.47.1'
  spec.add_development_dependency 'chromedriver-helper', '~> 1.0.0'
  spec.add_development_dependency 'poltergeist', '~> 1.5.0'
  spec.add_development_dependency 'thin', '~> 1.6.3'
  spec.add_development_dependency 'coveralls', '~> 0.8.1'

  spec.add_development_dependency 'guard', '2.12.7' # bug in current guard
  spec.add_development_dependency 'guard-rspec', '~> 4.3.0'
  spec.add_development_dependency 'rake', '~> 10.0.4'

  # Yard and formatting
  spec.add_development_dependency 'yard', '~> 0.8.7.0'

  spec.add_development_dependency 'rubocop', '~> 0.31.0'

  # NOTE: Some development dependencies are specified in the Gemfile because
  # bundler has platform support.
end
