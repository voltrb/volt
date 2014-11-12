source 'http://rubygems.org'

gemspec

# Run 0.7 from master until it comes out
gem 'opal', git: 'https://github.com/opal/opal.git'

group :development do
  # For testing the kitchen sink app
  # Twitter bootstrap
  gem 'volt-bootstrap'

  # Simple theme for bootstrap, remove to theme yourself.
  gem 'volt-bootstrap-jumbotron-theme'

  gem 'opal-rspec', git: 'https://github.com/opal/opal-rspec.git'

  # For testing
  gem 'volt-fields'

  # For testing
  gem 'volt-user-templates'

  # For running rubocop
  gem 'rubocop', require: false
end

group :development, :test do
  gem 'bson_ext'
end