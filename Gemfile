source 'http://rubygems.org'

gemspec

# volt-mongo gem for testing
gem 'volt-mongo'

# Use rbnacl for message bus encrpytion
# (optional, if you don't need encryption, disable in app.rb and remove)
gem 'rbnacl', require: false
gem 'rbnacl-libsodium', require: false

# temp until 0.8.0 of opal
# gem 'opal-rspec', github: 'opal/opal-rspec'

group :development, :test do
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
  platform :mri do

    # For running tests
    gem 'thin'
  end

  platform :jruby do
    # For running tests
    gem 'puma'
  end
end

platform :mri do
  # The implementation of ReadWriteLock in Volt uses concurrent ruby and ext helps performance.
  gem 'concurrent-ruby-ext'

  # For debugging
  gem 'pry-byebug', '~> 2.0.0', require: false

  # For Yard Formatting, in MRI block because redcarpet doesn't install on jruby
  gem 'redcarpet', '~> 3.2.2', require: false
  gem 'github-markup', '~> 1.3.1', require: false

  # Sauce has a dependency that doesn't run on ruby <= 2.0.0
  # (which older jruby versions don't support)
  # TODO: Move out of MRI block once jruby 9k is outs
  gem 'sauce', '~> 3.5.3', require: false
  gem 'sauce-connect', '~> 3.5.0', require: false

end
