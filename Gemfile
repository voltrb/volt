source 'http://rubygems.org'

gemspec

group :development do
  # For testing the kitchen sink app
  # Twitter bootstrap
  gem 'volt-bootstrap'

  # Simple theme for bootstrap, remove to theme yourself.
  gem 'volt-bootstrap_jumbotron_theme'

  # For testing
  gem 'volt-fields'

  # For testing
  gem 'volt-user_templates'

  # For running rubocop
  gem 'rubocop', require: false
end

group :development, :test do
  gem 'bson_ext'

  # For running tests
  gem 'thin'
end

platform :mri do
  # The implementation of ReadWriteLock in Volt uses concurrent ruby and ext helps performance.
  gem 'concurrent-ruby-ext'
end
