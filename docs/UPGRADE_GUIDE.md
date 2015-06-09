# 0.9.2 to 0.9.3

Upgrading from 0.9.2 should be fairly simple, just implement the following:

## Gemfile

Add the following to your gemfile:

```ruby
# Use rbnacl for message bus encrpytion
# (optional, if you don't need encryption, disable in app.rb and remove)
gem 'rbnacl', require: false
gem 'rbnacl-libsodium', require: false

# Asset compilation gems, they will be required when needed.
gem 'csso-rails', '~> 0.3.4', require: false
gem 'uglifier', '>= 2.4.0', require: false

gem 'volt-mongo'
```

## Store Promises

The api for accessing the store collection has changed, to better understand the changes, watch [this explainer video](https://www.youtube.com/watch?v=1RX9i8ivtWI).

## id vs _id

Everywhere you were using ```_id```, you should now just use ```id```.  Volt's mongo adaptor will map ```id``` to ```_id``` when saving or querying.  This change will make moving between databases easier.