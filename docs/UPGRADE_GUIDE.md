# 0.9.2 to 0.9.3

Add the following to your gemfile:

```ruby
# Use rbnacl for message bus encrpytion
# (optional, if you don't need encryption, disable in app.rb and remove)
gem 'rbnacl', require: false
gem 'rbnacl-libsodium', require: false

# Asset compilation gems, they will be required when needed.
gem 'csso-rails', '~> 0.3.4', require: false
gem 'uglifier', '>= 2.4.0', require: false
```