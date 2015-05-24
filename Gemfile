source 'http://rubygems.org'

gemspec

# volt-mongo gem for testing
gem 'volt-mongo', path: '/Users/ryanstout/Sites/volt/apps/volt-mongo'

# Use rbnacl for message bus encrpytion
# (optional, if you don't need encryption, disable in app.rb and remove)
gem 'rbnacl', require: false
gem 'rbnacl-libsodium', require: false


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
