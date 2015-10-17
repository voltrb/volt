# Change Log

## 0.9.6
0.9.6 is mostly a bug fix release with a few minor features.

### Added
- @merongivian was kind enough to add Spanish traslations to the docs: (http://docs.voltframework.com/es/index.html)
- @alexandred added user_connect/disconnect events (see docs)
- added a data transformer class used internally, but can also be used externally
- You can now boot apps in any ruby file by doing:
```ruby
require 'volt/boot'
Volt.boot(Dir.pwd)
```

### Changed
- Finally tracked down an illusive memory leak.
- Computations now raise an error on their inital run, then log errors (via Volt.logger.error(..)) when running again (since they update on next tick)
- fixed template caching issue
- upgrade the volt-mongo gem to mongo gem 2.1
- fixed issue with https web socket connection
- improved errors when returning objects from Tasks that can't be serialized
- validate! on models now rejects the promise when the model has errors.
- fixed template caching issue
- fixed page stash issue
- fixed Gemfile issue on windows
- fixed a memory leak

## 0.9.5
### Breaking Changes
- previously, we mounted the asset folders in components at /assets, and we also mounted the /app folder (and any gem's app folders') at /assets.  This allowed you to usually access what you wanted at /assets, but resulted in conflicts.  To ensure better component isolation, we now only mount the ```app``` folders.  To make things clear, instead of sprockets being mounted at /assets, it is now mounted at /app.  So the url for something in /app/main/assets/css/something.css can be accessed at (you guessed it) /app/main/assets/css/something.css

### Added
- You can now disable auto-import of JS/CSS with ```disable_auto_import``` in a dependencies.rb file
- Opal was upgraded to 0.8, which brings sourcemaps back (yah!)
- Page load performance was improved, and more of sprockets was used for component loading.
- You can now return promises in permissions blocks.  Also, can_read?, can_create?, and .can_delete? now return promises.
- Anything in /public is now served via Rack::Static in the default middleware stack.  (So you can put user uploaded images in there)
- You can now use _ or - in volt tag names and attributes.  (We're moving to using dash ( - ) as the standard in html)
- You can now trigger events on controllers rendered as tags.  The events will bubble up through the DOM and can be caught by any e- bindings.  See the docs for more information.
- Rewrote the precompile pipeline.
    - Added image compression by default. (using image_optim)
- All volt CLI tasks now can run from inside of any directory in the volt app (or the root)
- Asset precompilation has been reworked to use Sprockets::Manifest.  The results are written to /public, and an index.html file is created.  The entire app loading up until the websocket connect can be served statically (via nginx for example)  All js and css is written to a single file.
- The ```generate gem``` generator has been improved to setup a dummy app and integration specs out of the box.
- Tasks can now set (only set, not read) cookies on the client using the ```cookies``` collection.
- Added ```login_as(user)``` method to Tasks and HttpController's.
- [asset_url helper](http://docs.voltframework.com/en/deployment/README.html) in css/sass and html files
- Sourcemaps are enabled by default, you can disable them with ```MAPS=false``` env.  By default Volt and Opal code is not sourcemapped.  To enable sourcemaps for everything run with: ```MAPS=all``` (note this has a slight performance hit)  [Read the docs](http://docs.voltframework.com/en/docs/debugging.html) for more.

### Changed
- fix issue with ```raw``` and promises (#275)
- fix issue with .length on store (#269)
- The {root}/config/initializers directory is now only for server side code.
- Redid the initializer load order so all initializers run before any controllers/models/views are loaded.
- Added error message for when an unserializable object is returned from a Task
- Fixed issue with disable_encryption option
- Fixed issue with select's not selecting options when options are dynamically loaded

## 0.9.4
### Lingo Change
the base collections will now be called "Repositories" or "Repo's" for short.  This will only matter directly for internal volt code, but for the data provider api, this will help.

### Added
- ```root``` can now be called from a model to get the root model on the collection.  (So if the model is on store, it will return ```store```)
- ```store``` can now be called from inside of a model
- all repos (```store```, ```page```, ```cookies```, ```params```, etc...) now can be accessed outside of controllers and tasks with ```Volt.current_app.{repository}```  (```Volt.current_app.store``` for example)
- before_save was added to models.
- added ```cookies``` model for HttpController
- added support for serializing Time objects
- Model's now have a saved_state and saved? method.
- Volt.current_app now has ```store``` and ```page``` collections accessable from it, and is the preferred way to access those collections outside of controllers and tasks.

### Removed
- The $page global was removed.  Use ```Volt.current_app``` to get access to repos.

### Changed
- fixed bug with ReactiveHash#to_json
- fixed bug with field Numeric coersion
- fixed issue with initializers not loading on client sometimes.
- fixed issue with user password change
- fix issue storing Time in a hash
- fixed issue with local_store not persisting in some cases
- runners now block until messages have propigated to the message bus and updates have been pushed.
- upgraded some dependency gems to fix a conflict
- fixed bug with .last on ReactiveArray (#259)

## 0.9.3
[0.9.3 Update Blog Post](http://blog.voltframework.com/post/121128931859/0-9-3-stuff-you-asked-for)
[Upgrade Guide](https://github.com/voltrb/volt/blob/master/docs/UPGRADE_GUIDE.md)

### Added
- Added validations block for conditional validation runs
- you can now set the NO_FORKING=true ENV to prevent using the forking server in development.
- models without an assigned persistor now use the page persistor (which now can provide basic querying)
- Volt now pushes updates between mulitple app instances.  Updates are pushed between any servers, clients, runners, etc.. that are connected to the same database via the MessageBus (see next)
- Volt now comes with a "MessageBus" built in.  The message bus provides a pub/sub interface for the app "cluster".  Volt provides a default message bus implementation using peer to peer sockets that are automatically managed via the database.
- You can now nest models on store.  Previously store was limited to only storing either values or ArrayModels (associations).  You can now store directly, in mongo this will be stored as a nested value.
- Promises got more awesome.  Promises in volt can now proxy methods to their future resolved value.  Something like: ```promise.then {|v| v.name }``` can now be written simply as: ```promise.name```  It will still return a promise, but to make life easier:
- All bindings now support promises directly.
- All code in config/initializers is now run on app startup.
- All code in any components config/initializers (app/main/config/initializers/*.rb) is now run on the server during app startup.  On the client, only the included components initializers will be run.
- all initializers folders now support a ```client``` and ```server``` folder.
- has_one is now supported.
- You can now use .create to make a new item on a collection.
- .inspect for models is now cleaner
- Volt.current_user now works in HttpController's
- HttpControllers now can take promises in render.
- You can now add your own middleware to the middleware stack.  (see docs)
- Added a threadpool for Tasks, and options to customize pool size in config/app.rb
- Volt now handles Syntax errors much better, it will display an error message when your app does not compile, and can reload from that page when things change. (in development)
- Time objects can now be saved in models.

### Changed
- All methods on ArrayModel's under the store collection now return a Promise.
- A #create method was added to ArrayModel.
- All logic associated with mongo has been moved into the volt-mongo gem.  If you are migrating from a previous version, be sure to add ```gem 'volt-mongo'``` to the Gemfile.
- models using the page or store persistor now auto-generate an id when created.  This simplifies things since models always have an id.  It makes association easier as well. (internally that is)
- models now use ```.id``` instead of ```._id```  Queries and saves are mapped to _id in the volt-mongo gem
- fixed issue where ```volt precompile``` would compile in extra assets from non-component gems.
- Lots of internal changes:
    - bindings were refactored to pass around a Volt::App instead of a Volt::Page.
    - controllers now take a Volt::App when created directly.
- You can now use .each in attribute bindings.
- We moved to csso as the css compressor because it does not require libv8, only an execjs runtime.
- Each bindings now support promises.
- Volt.fetch_current_user has been deprecated and Volt.current_user now returns a promise.
- Volt.current_user? now returns a promise that yields a boolean
- Lots of bug fixes. (see github)

## 0.9.2
### Changed
- We released 0.9.1 with a bug for destroy (doh!).  Specs added and bug fixed.

## 0.9.1
[0.9.1 Update Blog Post](http://blog.voltframework.com/post/118260814159/0-9-1-already-thats-how-we-roll)

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
