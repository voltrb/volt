# 0.9.4 to 0.9.5

CSS url's now should be referenced either 1) as relative paths from the css file, or 2) using the full path from inside of app (eg: main/assets/images/background.jpg)

On models, .can_delete?, .can_read?, and .can_create? now return promises.

replace /config/base/index.html with:

```ruby
<!DOCTYPE html>
<html>
  <%# IMPORTANT: Please read before changing!                                   %>
  <%# This file is rendered on the server using ERB, so it does NOT use Volt's  %>
  <%# normal template system. You can add to it, but keep in mind the template  %>
  <%# language difference. This file handles auto-loading all JS/Opal and CSS.  %>
  <head>
    <meta charset="UTF-8" />
    <%= javascript_tags %>
    <%= css_tags %>
  </head>
  <body>

  </body>
</html>
```
Check the CHANGELOG for more info.

# 0.9.3 to 0.9.4

We moved logic out of Volt::User and into the generated user file, so it is easier to customize.  Add the following to your app/main/models/user.rb:

```ruby
# The login_field method returns the name that should be used for the field
# where the users e-mail is stored.  (usually :username or :email)
def self.login_field
  :email
end

# login_field is set to :email by default and can be set to
field login_field
field :name

validate login_field, unique: true, length: 8
validate :email, email: true
```

If you are using $page, it has been removed and you can now access any collection (which we're now calling repo's) via ```Volt.current_app.store``` or ```.page```, ```.params```, etc...

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