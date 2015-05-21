# Change Log

## 0.9.3.pre1
### Added
- Added validations block for conditional validation runs
- you can now set the NO_FORKING=true ENV to prevent using the forking server in development.


### Changed
- All logic associated with mongo has been moved into the volt-mongo gem.  If you are migrating from a previous version, be sure to add ```gem 'volt-mongo'``` to the Gemfile.
- fixed issue where ```volt precompile``` would compile in extra assets from non-component gems.
- Lots of internal changes:
    - bindings were refactored to pass around a Volt::App instead of a Volt::Page.
    - controllers now take a Volt::App when created directly.

## 0.9.2
### Changed
- We released 0.9.1 with a bug for destroy (doh!).  Specs added and bug fixed.

## 0.9.1
### Added
- Mailer! - volt now includes the volt-mailer gem out of the box.  (you can remove it if you don't need/want it).  See https://github.com/voltrb/volt-mailer for more info.

### Changed
- All code in ```app``` is now automatically reloaded when any files change.  This is done through a "preforking" server.  Before your apps code is loaded (and after Volt's is), the server forks a child process to handle the request (in dev and test mode).
- Corrected the name of StringTemplateRender to StringTemplateRenderer
- Volt now uses faye-websocket for socket connections.  This means we can run on any rack-hijack server supported by faye-websocket.  Currently Volt is tested with thin and puma.  (Note: Thin will probably have better performance since it is evented, which means it doesn't need a thread per connection)  More servers coming soon.
- originally everything in /config would be run when an app boots (similar to rails initializers folder).  The issue we didn't see is things like capistrano that store other ruby files in config.  To maintain conventions, Volt now loads config/app.rb first, then everything in config/initializers/*.rb
- fixed issue with the unique validation.
- made it so <:SectionName> can be accessed by <:section_name /> tag
- fixed issue with if bindings not resolving some promises.
- fixed issue with require's in controllers.
- fix class formatting issue with Pry.
- Bundler.require is now called for the correct env when 'volt/boot' is included.  (We weren't planning to do this, but it does make life so much easier)
- opal-jquery was removed as a dependency.  If you want to use it again, add ```gem 'opal-jquery'``` to your Gemfile and add ```require 'opal/jquery'` to your MainController.
- Volt and new gems now use the standard ruby version.rb file.

## 0.9.0
### Added
- the permissions api has been added!
- added has_many and belongs_to on models.  See docs.
- you can now serve http/rest from Volt.  Thanks to @jfahrer for his great work.  More docs coming soon.
- there is now a generator for controllers and HttpControllers.
- fixed generated component code
- added .order for sorting on the data store (since .sort is a ruby Enum method)
- calling .then on ArrayModels has been changed to calling .fetch and .fetch_first.  These both return a promise, and take an optional block
- added .sync for synchronusly waiting on promises on the server only
- added the ability to pass content into tags: (https://github.com/voltrb/docs/blob/master/en/docs/yield_binding.md)
- Changed it so content bindings escape all html (for CSRF - thanks @ChaosData)
- Added formats, email, phone validators (thanks @lexun and @kxcrl)
- each_with_index is now supported in views and the ```index``` value is no longer provided by default.
- fixed bug with cookie parsing with equals in them
- fixed bug appending existing models to a collection
- refactored TemplateBinding, moved code into ViewLookupForPath (SRP)
- reserved fields now get a warning in models
- bindings will now resolve any values that are promises. (currently only content and attribute, if, each, and template coming soon)
- ```store``` is now available inside of specs.  If it is accessed in a spec, the database will be cleaned after the spec.
- ```the_page``` is a shortcut to the page collection inside of specs.  (Unfortunately, ```page``` is used by capybara, so for now we're using ```the_page```, we'll find a better solution in the future.)
- Add filtering to logging on password, and option to configure filtered args.  Also, improve the way errors are displayed.
- You can now call raw in a content binding to render the raw html on the page.  Use carefully, this can open you up to xss attacks.  We reccomend never showing html from the user directly.
- before/after actions added to ModelController (HttpController support coming soon).
- in the disabled attribute, you can now bind to a boolean or string.
- added a .fetch_each method that fetches all items, then yields each one.

### Changed
- template bindings have been renamed to view.  ```{{ view "path/for/view" }}``` instead of ```{{ template "path/for/view" }}```
- view bindings (formerly template) wait until the template's #loaded? method returns true (by .watch! ing it for changes)
- #loaded? on controllers now returns false if the model is set to a Promise, until the promise is resolved.
- the {action}_remove method had been changed to before_{action}_remove and after_{action}_remove to provide more hooks and a clearer understanding of when it is happening.
- the following were renamed to follow gem naming conventions:
  - volt-user-templates (now volt-user_templates)
  - volt-bootstrap-jumbotron-theme (now volt-bootstrap_jumbotron_theme)
- all plural attributes now return an empty ArrayModel.  This is to simplify implementation and to unify store's interface.
- main_path in generated projects now includes the a component param that can be used to easily point at controllers/views in other components.
- previously the main component's controllers were not namespaced.  We changed it so all controllers (including those in main) are namespaced.  This is makes things more consistent and keeps expectations when working with components.
- model attributes no longer return NilModels.  Instead they just return nil.  You can however add an ! to the end to "expand" the model to an empty model.

    ```page._new_todo # => now returns nil```

    ```page._new_todo! # => returns an empty model```

  So if you wanted to use a property on ```_new_todo``` without initializing ```_new_todo```, you could add the ! to the lookup.
- Volt.user has been renamed to Volt.current_user so its clearer what it returns
- _'s are no longer required for route constraints (so just use ```controller: 'main', action: 'index'``` now)
- the underlying way queries are normalized and passed to the server has changed (no external api changes)
- changed .find to .where to not conflict with ruby Enum's .find
- Volt::TaskHandler is now Volt::Task
- Move testing gems to the generated Gemfile for projects
- ```if ENV['BROWSER']``` is no longer required around integration tests.  We now use rspec filtering on ```type: :feature``` if you aren't running with ENV['BROWSER']
- ```go``` has been renamed to ```redirect_to``` to keep things consistent between ruby frameworks. (And to allow for go to be used elsewhere)

### Removed
- .false?, .true?, .or, and .and were removed since NilModels were removed.  This means you get back a real nil value when accessing an undefined model attribute.

## 0.8.24 - 2014-12-05
### Added
- Fix bug with validation inheritance
- Fixed issue with controller loading.

## 0.8.23 - 2014-11-30
### Added
- Added url_for and url_with to controllers.  (See docs under Controllers)

## 0.8.22 - 2014-11-16
### Added
- Volt.config is now accessable from the client.
- Added ```.try``` to Object
- Added Volt.login
- successful asset loads are not logged in development
- Basics of users is now place, along with including the default user templates gem
  - more user related helpers in the works

## 0.8.21 - 2014-11-05
### Changed
- fix merge conflict

## 0.8.20 - 2014-11-05
### Changed
- fix secure random bug from 0.8.19 :-)

## 0.8.19 - 2014-11-05
### Breaking Changes
- the default index page is now moved from ```public/index.html``` to ```config/base/index.html```  Please update your app's accordingly.  Since the public page is essentially static at the moment, public will only be used for asset pre-compilation (and index.html will be rendered in place)
- validations do not use underscore for the field name

### Added
- you can precompile an app with ```bundle exec volt precompile``` - still a work in process
- update flash to handle successes, notices, warnings, errors.
- Add .keys to models (you can use .keys.each do |key| until we get .each_pair binding support)
- added ```cookies``` collection.  See docs for more info
- ```validate :field_name, unique: true``` now supported (scope coming soon)
- added custom validations by passing a block to ```validate``` and returning a hash of errors like ```{field_name => ['...', '...']}```

## 0.8.18 - 2014-10-26
### Added
- Added a default app.css.scss file

### Changed
- back button fixed
- improve security on task dispatcher
- lots of minor bug fixes

## 0.8.17 - 2014-10-20
### Added
- Volt now has a runner task (like rails) so you can run .rb files inside of the volt project.  Example: ```volt runner lib/import.rb```
- New video showing pagination: https://www.youtube.com/watch?v=1uanfzMLP9g

## 0.8.16 - 2014-10-20
### Added
- Change changelog format to match: http://keepachangelog.com/
- Added rubocop config and ran rubocop on repo, lots of changes.
- Added .limit and .skip to cursors
- Changed: ```attrs``` now return nil for attributes that weren't passed in.

# 0.8.15 - Oct 18, 2014

  - MAJOR CHANGE: everything volt related now is under the Volt module.  The only change apps need to think about is inheriting from ```Volt::ModelController``` and ```Volt::Model```  Also, config.ru needs to use ```Volt::Server``` instead of ```Server```.

# 0.8.10 - Oct 12, 2014
  - url.query, url.fragment, url.path all update reactively now.
  - MAJOR CHANGE: Previously all tables and fields were created with _'s as their name prefixes.  The underscores have been removed from everywhere.  The only place you use underscores is when you want to access fields without creating setters and getters.  Now when you do: ```model._name = 'Something'```, your setting the ```name``` attribute on the model.  When you do: ```model._name```, your fetching the ```name``` attribute.  If you insert a hash into a collection, you no longer use underscores:

  ```ruby
    store._items << {name: 'Item 1'}
  ```

    Continue using underscores in routes.


# 0.8.6 - Oct 5, 2014

  - Major changes to the templating system (to address common concerns and make things simpler).
      1. All binding now takes place between ```{{ and }}``` instead of ```{ and }``` (double stash instead of single stash)  Escaping is still with a tripple stash ```{{{ escap{{ed}} }}}```  => escap{{ed}}
      2. Bindings can now be (almost) any ruby code.  No more #'s at the beginning.  Blocks are now closed with {{ end }}
            If's are now: ```{{ if _something }}``` ... ```{{ elsif _other }}``` .. ```{{ else }}``` .. ```{{ end }}```
            Each's are now: ```{{ _items.each do |item| }}``` ... ```{{ end }}```
            Template bindings are now: ```{{ template "path" }}``` (along with other options)
            Each should use do notation not brackets.  Also, .each is not actually called, the binding is parsed and converted into a EachBinding.  Other Eneumerable methods do not work at this time, only each.  (more coming soon)
      3. Bindings in routes now use double stashes as well get '/products/{{ _name }}/info'
      4. To help clean things up, we reccomend spaces between ```{{``` and ```}}```


# 0.8.4 - Oct 4, 2014

  - Added configuration for databases.

# 0.8.0 - Oct 3, 2014

  - Major change: After a bunch of research and effort, we have decided to change the way the reactive core works.  Previously, all objects that maybe changed would be wrapped in a ReactiveValue object that could be updated using ```.cur=``` and accessed using ```.cur```  This had many advantages, but resulted in very complex framework code.  It also had a few problems, mainly that reactive value's (sometimes) needed to be unwrapped when passed to code that wasn't aware of reactivity.  Our goal is transparent reactivity.  Taking infuence from meteor.js, we have switched to a simpler reactive model.  See the Readme for details of the new reactive system.  The new system has a few advantages.  Mainly, you can for the most part write code that is reactive and it will just work.
  - Radio button support has been added, see README.md
  - Added docs for select box bindings
  - Previously attributes passed into controls were accessable as instance variables.  Due to the way the new reactive system works, to bind data it needs to be fetched through a method or function call.  To make this work, attributes passed in as an object.  The object can be accessed with ```data```, so if you have a tag like:
      ```<:nav link="/blog" text="Blog" />```

      Within the template or controller you can access link and text as ```data.link``` and ```data.text```

      ```html
      <:Nav>
        <li><a href="{data.link}">{data.text}</a></li>
      ```

      ```ruby
        class Nav < ModelController
          def link_url
            return data.link
          end
        end
      ```
