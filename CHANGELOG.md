# Change Log

## 0.8.27 - WIP
### Added
- _'s are no longer required for route constraints (so just use ```controller: 'main', action: 'index'``` now)
- fixed generated component code
- added .order for sorting on the data store (since .sort is a ruby Enum method)
- changed .find to .where to not conflict with ruby Enum's .find
- added .fetch and .fetch_first for waiting on store model loads
- added .sync for synchronusly waiting on promises on the server only
- added the ability to pass content into tags: (https://github.com/voltrb/docs/blob/master/en/docs/yield_binding.md)
- the {action}_remove method had been changed to before_{action}_remove and after_{action}_remove to provide more hooks and a clearer understanding of when it is happening.
- Changed it so content bindings escape all html (for CSRF - thanks @ChaosData)
- Added formats, email, phone validators (thanks @lexun and @kxcrl)
- each_with_index is now supported in views and the ```index``` value is no longer provided by default.
- fixed bug with cookie parsing with equals in them
- fixed bug appending existing models to a collection
- refactored TemplateBinding, moved code into ViewLookupForPath (SRP)
- reserved fields now get a warning in models
- bindings will now resolve any values that are promises. (currently only content and attribute, if, each, and template coming soon)

### Changed
- the underlying way queries are normalized and passed to the server has changed (no external api changes)

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
