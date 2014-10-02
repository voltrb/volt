[![Gem Version](https://badge.fury.io/rb/volt.png)](http://badge.fury.io/rb/volt)
[![Code Climate](https://codeclimate.com/github/voltrb/volt.png)](https://codeclimate.com/github/voltrb/volt)
[![Build Status](https://travis-ci.org/voltrb/volt.png?branch=master)](https://travis-ci.org/voltrb/volt)
[![Inline docs](http://inch-ci.org/github/voltrb/volt.svg?branch=master)](http://inch-ci.org/github/voltrb/volt)
[![Volt Chat](https://badges.gitter.im/voltrb/volt.png)](https://gitter.im/voltrb/volt)

** For the current status of volt, read: http://voltframework.com/blog

# Volt

Volt is a Ruby web framework where your ruby code runs on both the server and the client (via [opal](https://github.com/opal/opal)).  The DOM automatically update as the user interacts with the page. Page state can be stored in the URL. If the user hits a URL directly, the HTML will first be rendered on the server for faster load times and easier indexing by search engines.

Instead of syncing data between the client and server via HTTP, Volt uses a persistent connection between the client and server. When data is updated on one client, it is updated in the database and any other listening clients (with almost no setup code needed).

Pages HTML is written in a handlebars-like template language.  Volt uses data flow/reactive programming to automatically and intelligently propagate changes to the DOM (or anything other code wanting to know when a value updates).  When something in the DOM changes, Volt intelligently updates only the nodes that need to be changed.

See some demo videos here:
 - [Volt Todos Example](https://www.youtube.com/watch?v=6ZIvs0oKnYs)
 - [Build a Blog with Volt](https://www.youtube.com/watch?v=c478sMlhx1o)
 - [Reactive Values in Volt](https://www.youtube.com/watch?v=yZIQ-2irY-Q)

Check out demo apps:
 - https://github.com/voltrb/todos3
 - https://github.com/voltrb/blog
 - https://github.com/voltrb/contactsdemo


## Goals

Volt has the following goals:

1. Developer happiness
2. Write once on the client and server
3. Automatic data syncing between client and server
4. Apps are built as nested components.  Components can be shared (via gems)
5. Concurrent.  Volt provides tools to simplify concurrency.  Component rendering is done in parallel on the server
6. Intelligent asset management
7. Secure (shouldn't need to be said, but it does)
8. Be fast/light
9. Understandable code base
10. Control upgradeability

# Road Map

Many of the core Volt features are implemented.  We still have a bit to go before 1.0, most of it involving models.

1. Reactive model queries
2. Reactive Enumerators with Blocks (.map .count, etc…)
3. Full managed render loop (for fast rendering)
4. Fix N+1 issue with some reactive values (I know how to fix it, just haven't gotten around to doing it)

# VOLT guide

This guide will take you through creating a basic web application in Volt.  This tutorial assumes a basic knowledge of Ruby and web development.

To get started, install Volt:

    gem install volt

Then create a new project:

    volt new project_name

This will setup a basic project.  Now let's run the server:

    bundle exec volt server

You can access the Volt console with:

    bundle exec volt console

# Guide Sections

1. [Getting Help](#getting-help)
2. [Rendering](#rendering)
  1. [Reactive Values](#reactive-values)
    1. [ReactiveValue Gotchas](#reactivevalue-gotchas)
3. [Views](#views)
  1. [Bindings](#bindings)
    1. [Content Binding](#content-binding)
    2. [If Binding](#if-binding)
    3. [Each Binding](#each-binding)
    4. [Attribute Bindings](#attribute-bindings)
    5. [Escaping](#escaping)
4. [Models](#models)
  1. [Provided Collections](#provided-collections)
  2. [Reactive Models](#reactive-models)
  3. [Model Events](#model-events)
  4. [Automatic Model Conversion](#automatic-model-conversion)
5. [Controllers](#controllers)
6. [Tasks](#tasks)
7. [Components](#components)
  1. [Dependencies](#dependencies)
  2. [Assets](#assets)
  3. [Component Generator](#component-generator)
  4. [Provided Components](#provided-components)
    1. [Notices](#notices)
    2. [Flash](#flash)
8. [Controls](#controls)
9. [Routes](#routes)
  1. [Routes file](#routes-file)
10. [Testing](#testing)


# Getting Help

Volt is still a work in progress, but early feedback is appreciated.  Use the following to communicate with the developers, someone will get back to you very quickly:

- **If you need help**: post on [stackoverflow.com](http://www.stackoverflow.com). Be sure to tag your question with `voltrb`.
- **If you found a bug**: post on [github issues](https://github.com/voltrb/volt/issues)
- **If you have an idea or need a feature**: post on [github issues](https://github.com/voltrb/volt/issues)
- **If you want to discuss Volt**: use #voltrb on freenode.


# Rendering

When a user interacts with a web page, typically we want to do two things:

1. Change application state
2. Update the DOM

For example when a user clicks to add a new todo item to a todo list, we might create a JavaScript object to represent the todo item, then add an item to the list's DOM.  A lot of work needs to be done to make sure that the JavaScript object and the DOM always stay in sync.

The idea of "reactive programming" has been used to simplify maintaining the DOM.  The idea is instead of having event handlers that manage a model (or JavaScript object) and manage the DOM, we have event handlers that manage reactive data models.  We describe our DOM layer in a declarative way so that it automatically knows how to render our data models.

## Reactive Values

To build bindings, Volt provides the ReactiveValue class.  This wraps any object in a reactive interface.  To create a ReactiveValue, simply pass the object you want to wrap as the first argument to new.

```ruby
    a = ReactiveValue.new("my object")
    # => @"my object"
```

When `#inspect` is called on a ReactiveValue (like in the console), an '@' is placed in front of the value's inspect string, so you know it's reactive.

When you call a method on a ReactiveValue, you get back a new reactive value that depends on the previous one.  It remembers how it was created and you can call `#cur` on it any time to get its current value, which will be computed based off of the first reactive value.  (Keep in mind below that + is a method call, the same as `a.+(b)` in ruby.)

```ruby
    a = ReactiveValue.new(1)
    a.reactive?
    # => true

    a.cur
    # => 1

    b = a + 5
    b.reactive?
    # => true

    b.cur
    # => 6

    a.cur = 2
    b.cur
    # => 7
```

This provides the backbone for reactive programming.  We setup computation/flow graphs instead of doing an actual calculation.  Calling `#cur` (or `#inspect`, `#to_s`, etc..) runs the computation and returns the current value at that time, based on all of its dependencies.

ReactiveValues also let you setup listeners and trigger events:

```ruby
    a = ReactiveValue.new(0)
    a.on('changed') { puts "A changed" }
    a.trigger!('changed')
    # => A Changed
```

These events propagate to any reactive values created off of a reactive value:

```ruby
    a = ReactiveValue.new(1)
    b = a + 5
    b.on('changed') { puts "B changed" }

    a.trigger!('changed')
    # => B changed
```

This event flow lets us know when an object has changed, so we can update everything that depended on that object.

Lastly, we can also pass in other reactive values as arguments to methods on a reactive value.  The dependencies will be tracked for both and events will propagate down from both.  (Also, note that calling `#cur=` to update the current value triggers a "changed" event.)

```ruby
    a = ReactiveValue.new(1)
    b = ReactiveValue.new(2)
    c = a + b

    a.on('changed') { puts "A changed" }
    b.on('changed') { puts "B changed" }
    c.on('changed') { puts "C changed" }

    a.cur = 3
    # => A changed
    # => C changed

    b.cur = 5
    # => B changed
    # => C changed
```

### ReactiveValue Gotchas

There are a few simple things to keep in mind with ReactiveValues.  In order to make them mostly compatible with other Ruby objects, two methods do not return another ReactiveValue.

    to_s and inspect

If you want these to be used reactively, see the section on [with](#with).

Also, due to a small limitation in ruby, ReactiveValues always are truthy.  See the [truthy checks](#truthy-checks-true-false-or-and-and) section on how to check for truth.

When passing something that may contain reactive values to a JS function, you can call ```#deep_cur``` on any object to get back a copy that will have all reactive values turned into their current value.

### Current Status

NOTE: currently ReactiveValues are not complete.  At the moment, they do not handle methods that are passed blocks (or procs, lambdas).  This is planned, but not complete.  At the moment you can use [with](#with) to accomplish similar things.

### Truthy Checks: .true?, .false?, .or, and .and

Because a method on a reactive value always returns another reactive value, and because only nil and false are false in ruby, we need a way to check if a ReactiveValue is truthy in our code.  The easiest way to do this is by calling .true? on it.  It will return a non-wrapped boolean.  .nil? and .false? do as you would expect.

One common place we use a truthy check is in setting up default values with || (logical or)  Volt provides a convenient method that does the same thing `#or`, but works with ReactiveValues.

Instead of

```ruby
    a || b
```

Simply use:

```ruby
    a.or(b)
```

`#and` works the same way as &&.  #and and #or let you maintain the reactivity all of the way through.


### With

Normally when you want to have a value that depends on another value, but transforms it somehow, you simply call your transform method on the ReactiveValue.  However sometimes the transform is not directly on the ReactiveValues object.

You can call `#with` on any ReactiveValue.  `#with` will return a new ReactiveValue that depends on the current ReactiveValue.  `#with` takes a block, the first argument to the block will be the cur value of the ReactiveValue you called `#with` on.  Any additional arguments to `#with` will be passed in after the first one.  If you pass another ReactiveValue as an argument to `#with`, the returned ReactiveValue will depend on the argument ReactiveValue as well, and the block will receive the arguments cur value.

```ruby
    a = ReactiveValue.new(5)
    b = a.with {|v| v + 10 }
    b.cur
    # => 15
```

# Views

Views in Volt use a templating language similar to handlebars. They can be broken up into sections. A section header looks like the following:

```html
<:Body>
```

Section headers should start with a capital letter so as not to be confused with [controls](#controls).  Section headers do not use closing tags.  If section headers are not provided, the Body section is assumed.

Sections help you split up different parts of the same content (title and body usually), but within the same file.

## Bindings

Once you understand the basics of ReactiveValues, we can discuss bindings. In Volt, you code your views in a handlebars like template language.  Volt provides several bindings, which handle rendering of something for you. Content bindings are anything inbetween { and }.

### Content binding

The most basic binding is a content binding:

```html
    <p>{some_method}<p>
```

The content binding runs the Ruby code between { and }, then renders the return value.  If the returned value is a ReactiveValue, it will update the value updated whenever a 'changed' event is triggered on the reactive value.

### If binding

An if binding lets you provide basic flow control.

```html
    {#if _some_check?}
      <p>render this</p>
    {/}
```

Blocks are closed with a {/}

When the if binding is rendered, it will run the ruby code after #if.  If the code is true it will render the code below.  Again, if the returned value is reactive, it will update as that value changes.

If bindings can also have #elsif and #else blocks.

```html
    {#if _condition_1?}
      <p>condition 1 true</p>
    {#elsif _condition_2?}
      <p>condition 2 true</p>
    {#else}
      <p>neither true</p>
    {/}
```

### Each binding

For iteration over objects, the each binding is provided.

```html
    {#each _items as item}
      <p>{item}</p>
    {/}
```

Above, if _items were an array, the block would be rendered for each item, setting 'item' to the value of the array element.

You can also access the position of the item in the array with the #index method.

```html
    {#each _items as item}
      <p>{index}. {item}</p>
    {/}
```

For the array: ['one', 'two', 'three'] this would print:

    0. one
    1. two
    2. three

You can do {index + 1} to correct the zero offset.

When items are removed or added to the array, the #each binding automatically and intelligently adds or removes the items from/to the DOM.

## Attribute Bindings

Bindings can also be placed inside of attributes.

```html
    <p class="{#if _is_cool?}cool{/}">Text</p>
```

There are some special features provided to make elements work as "two way bindings":

```html
    <input type="text" value="{_name}" />
```

In the example above, if _name changes, the field will update, and if the field is updated, _name will be changed:

```html
    <input type="checkbox" checked="{_checked}" />
```

If the value of a checked attribute is true, the checkbox will be shown checked. If it's checked or unchecked, the value will be updated to true or false.

-- TODO: select boxes

If you have a controller at app/home/controller/index_controller.rb, and a view at app/home/views/index/index.html, all methods called are called on the controller.

## Escaping

When you need to use { and } outside of bindings, anything in a triple mustache will be escaped and not processed as a binding:

```html
    {{{ bindings look like: {this}  }}}
```

# Models

Volt's concept of a model is slightly different from many frameworks where a model is the name for the ORM to the database.  In Volt a model is a class where you can store data easily.  Models can be created with a "Persistor", which is responsible for storing the data in the model.  Models created without a persistor, simply store the data in the classes instance.  Lets first see how to use a model.

Volt comes with many built-in models; one is called `page`.  If you call `#page` on a controller, you will get access to the model.  Models provided by Volt are automatically wrapped in a ReactiveValue so update events can be tracked.

```ruby
    page._name = 'Ryan'
    page._name
    # => @'Ryan'
```

Models act like a hash that you can access with getters and setters that start with an _ .  If an underscore method is called that hasn't yet been assigned, you will get back a "nil model".  Prefixing with an underscore makes sure we don't accidentally try to call a method that doesn't exist and get back nil model instead of raising an exception.  There is no need to define which fields a model has. Fields behave similarly to a hash, but with a different access and assignment syntax.

Models also let you nest data without creating the intermediate models:

```ruby
    page._settings._color = 'blue'
    page._settings._color
    # => @'blue'

    page._settings
    # => @#<Model:_settings {:_color=>"blue"}>
```

Nested data is automatically setup when assigned.  In this case, page._settings is a model that is part of the page model.

You can also append to a model if it's not defined yet.  In Volt models, plural properties are assumed to contain arrays (or more specifically, ArrayModels).

```ruby
    page._items << 'item 1'
    page._items
    # => @#<ArrayModel ["item 1", "item 2"]>

    page._items[0]
    # => @"item 1"
```

ArrayModels can be appended to and accessed just like regular arrays.

## Provided Collections

Above, I mentioned that Volt comes with many default collection models accessible from a controller.  Each stores in a different location.

| Name      | Storage Location                                                          |
|-----------|---------------------------------------------------------------------------|
| page      | page provides a temporary store that only lasts for the life of the page. |
| store     | store syncs the data to the backend database and provides query methods.  |
| session   | values will be stored in a session cookie.                                |
| params    | values will be stored in the params and URL.  Routes can be setup to change how params are shown in the URL.  (See routes for more info) |
| flash     | any strings assigned will be shown at the top of the page and cleared as the user navigates between pages. |
| controller| a model for the current controller                                        |

**more storage locations are planned**

## Reactive Models

Because all models provided by Volt are wrapped in a ReactiveValue, you can register listeners on them and be updated when values change.  You can also call methods on their values and get updates when the sources change.  Bindings also setup listeners.  Models should be the main place you store all data in Volt.  While you can use ReactiveValues manually, most of the time you will want to just use something like the controller model.

## Model Events

Models trigger events when their data is updated.  Currently, models emit three events: changed, added, and removed.  For example:

```ruby
    model = Model.new

    model._name.on('changed') { puts 'name changed' }
    model._name = 'Ryan'
    # => name changed

    model._items.on('added') { puts 'item added' }
    model._items << 1
    # => item added

    model._items.on('removed') { puts 'item removed' }
    model._items.delete_at(0)
    # => item removed
```

## Automatic Model Conversion

### Hash -> Model

For convenience, when placing a hash inside of another model, it is automatically converted into a model.  Models are similar to hashes, but provide support for things like persistence and triggering reactive events.

```ruby
    user = Model.new
    user._name = 'Ryan'
    user._profiles = {
      _twitter: 'http://www.twitter.com/ryanstout',
      _dribbble: 'http://dribbble.com/ryanstout'
    }

    user._name
    # => "Ryan"
    user._profiles._twitter
    # => "http://www.twitter.com/ryanstout"
    user._profiles.class
    # => Model
```

Models are accessed differently from hashes.  Instead of using `model[:symbol]` to access, you call a method `model.method_name`.  This provides a dynamic unified store where setters and getters can be added without changing any access code.

You can get a Ruby hash back out by calling `#to_h` on a Model.

### Array -> ArrayModel

Arrays inside of models are automatically converted to an instance of ArrayModel.  ArrayModels behave the same as a normal Array except that they can handle things like being bound to backend data and triggering reactive events.

```ruby
    model = Model.new
    model._items << {_name: 'item 1'}
    model._items.class
    # => ArrayModel

    model._items[0].class
    # => Model
    model._items[0]
```


To convert a Model or an ArrayModel back to a normal hash or a normal array, call .to_h or .to_a respectively.  To convert them to a JavaScript Object (for passing to some JavaScript code), call `#to_n` (to native).

```ruby
    user = Model.new
    user._name = 'Ryan'
    user._profiles = {
      twitter: 'http://www.twitter.com/ryanstout',
      dribbble: 'http://dribbble.com/ryanstout'
    }

    user._profiles.to_h
    # => {twitter: 'http://www.twitter.com/ryanstout', dribbble: 'http://dribbble.com/ryanstout'}

    items = ArrayModel.new([1,2,3,4])
    items.to_a
    # => [1, 2, 3, 4]
```

You can get a normal array again by calling .to_a on an ArrayModel.

# Controllers

A controller can be any class in Volt, however it is common to have that class inherit from ModelController.  A model controller lets you specify a model that the controller works off of.  This is a common pattern in Volt.  The model for a controller can be assigned by one of the following:

1. A symbol representing the name of a provided collection model:

```ruby
    class TodosController < ModelController
      model :page

      # ...
    end
```

2. Calling `self.model=` in a method:

```ruby
    class TodosController < ModelController
      def initialize
        self.model = :page
      end
    end
```

In methods, the `#model` method returns the current model.

See the [provided collections](#provided-collections) section for a list of the available collection models.

You can also provide your own object to model.

In the example above, any methods not defined on the TodosController will fall through to the provided model.  All views in views/{controller_name} will have this controller as the target for any Ruby run in their bindings.  This means that calls on self (implicit or with self.) will have the model as their target (after calling through the controller).  This lets you add methods to the controller to control how the model is handled, or provide extra methods to the views.

Volt is more similar to an MVVM architecture than an MVC architecture.  Instead of the controllers passing data off to the views, the controllers are the context for the views.  When using a ModelController, the controller automatically forwards all methods it does not handle to the model.  This is convenient since you can set a model in the controller and then access its properties directly with methods in bindings.  This lets you do something like ```{_name}``` instead of something like ```{@model._name}```

Controllers in the app/home component do not need to be namespaced, all other components should namespace controllers like so:

```ruby
    module Auth
      class LoginController < ModelController
        # ...
      end
    end
```

Here "auth" would be the component name.

## Reactive Accessors

The default ModelController proxies any missing methods to its model.  Since models are wrapped in ReactiveValues, they return ReactiveValues by default.  Sometimes you need to store additional data reactively in the controller outside of the model.  (Though often you may want to condier doing another control/controller).  In this case, you can add a ```reactive_accessor```.  These behave just like ```attr_accessor``` except the values assigned and returned are wrapped in a ReactiveValue.  Updates update the existing ReactiveValue.

```ruby
  class Contacts < ModelController
    reactive_accessor :_query
  end
```

Now from the view we can bind to _query while also changing in and out the model.  You can also use ```reactive_reader``` and ```reactive_writer```

# Tasks

Sometimes you need to explicitly execute some code on the server. Volt solves this problem through *tasks*. You can define your own tasks by dropping a class into your component's ```tasks``` folder.

```ruby
    # app/main/tasks/logging_tasks.rb

    class LoggingTasks
        def initialize(channel=nil, dispatcher=nil)
            @channel = channel
            @dispatcher = dispatcher
        end

        def log(message)
            puts message
        end
    end
```

To invoke a task from a controller use ```tasks.call```.

```ruby
    class Contacts < ModelController
        def hello
            tasks.call('LoggingTasks', 'log', 'Hello World!')
        end
    end
```

You can also pass a block to ```tasks.call``` that will receive the return value of your task as soon as it's done.

```ruby
    tasks.call('MathTasks', 'add', 23, 5) do |result|
        # result should be 28
        alert result
    end
```

# Components

Apps are made up of Components.  Each folder under app/ is a component.  When you visit a route, it loads all of the files in the component on the front end, so new pages within the component can be rendered without a new http request.  If a URL is visited that routes to a different component, the request will be loaded as a normal page load and all of that components files will be loaded.  You can think of components as the "reload boundary" between sections of your app.

## Dependencies

You can also use controls (see below) from one component in another.  To do this, you must require the component from the component you wish to use them in.  This can be done in the ```config/dependencies.rb``` file.  Just put

```ruby
    component 'component_name'
```

in the file.

Dependencies act just like require in ruby, but for whole components.

Sometimes you may need to include an externally hosted JS file from a component.  To do this, simply do the following in the dependencies.rb file:

```ruby
    javascript_file 'http://code.jquery.com/jquery-2.0.3.min.js'
    css_file '//netdna.bootstrapcdn.com/bootstrap/3.0.3/css/bootstrap.min.css'
```

Note above though that jquery and bootstrap are currently included by default.  Using javascript_file and css_file will be mixed in with your component assets at the correct locations according to the order they occur in the dependencies.rb files.

## Assets

**Note, asset management is still early, and likely will change quite a bit**

In Volt, assets such as JavaScript and CSS (or sass) are automatically included on the page for you.  Anything placed inside of a components asset/js or assets/css folder is served at /assets/{js,css} (via [Sprockets](https://github.com/sstephenson/sprockets)).  Link and script tags are automatically added for each css and js file in assets/css and assets/js respectively.  Files are included in their lexical order, so you can add numbers in front if you need to change the load order.

Any JS/CSS from an included component or component gem will be included as well.  By default [bootstrap](http://getbootstrap.com/) is provided by the volt-bootstrap gem.

**Note: asset bundling is on the TODO list**

## Component Generator

Components can easily be shared as a gem.  Volt provides a scaffold for component gems.  In a folder (not in a volt project), simply type: volt gem {component_name}  This will create the files needed for the gem.  Note that all volt component gems will be prefixed with volt- so they can easily be found by others on github and rubygems.

While developing, you can use the component by placing the following in your Gemfile:

```ruby
gem 'volt-{component_name}', path: '/path/to/folder/with/component'
```

Once the gem is ready, you can release it to ruby gems with:

    rake release

Remove the path: option in the gemfile if you wish to use the rubygems version.

## Provided Components

Volt provides a few components to make web developers' lives easier.

### Notices

Volt automatically places ```<:volt:notices />``` into views.  This shows notices for the following:

1. flash messages
2. connection status (when a disconnect happens, lets the user know why and when a reconnect will be attempted)
3. page reloading notices (in development)

### Flash

As part of the notices component explained above, you can append messages to any collection on the flash model.

Each collection represents a different type of "flash".  Common examples are ```_notices, _warnings, and _errors```  Using different collections allows you to change how you want the flash displayed.  For example, you might want ```_notices``` and ```_errors``` to show with different colors.

```ruby
    flash._notices << "message to flash"
```

These messages will show for 5 seconds, then disappear (both from the screen and the collection).

# Controls

Everyone wishes that we could predict the scope and required features for each part of our application, but in the real world, things we don't expect to grow large often do and things we think will be large don't end up that way.  Controls let you quickly setup reusable code/views.  The location of the controls code can be moved as it grows without changing the way controls are invoked.

To render a control, simply use a tag like so:

```html
    <:control-name />
```

or

```html
    <:control-name></:control-name>
```

To find the control's views and optional controller, Volt will search the following (in order):


| Section   | View File    | View Folder    | Component   |
|-----------|--------------|----------------|-------------|
| :{name}   |              |                |             |
| :body     | {name}.html  |                |             |
| :body     | index.html   | {name}         |             |
| :body     | index.html   | index          | {name}      |
| :body     | index.html   | index          | gems/{name} |

**Note that anything with a view folder will also load a controller if the name/folder matches.**


Each part is explained below:

1. section
Views are composed of sections.  Sections start with a ```<:SectionName>``` and are not closed.  Volt will look first for a section in the same view.

2. views
Next Volt will look for a view file with the control name.  If found, it will render the body section of that view.

3. view folder
Failing above, Volt will look for a view folder with the control name, and an index.html file within that folder.  It will render the :body section of that view.  If a controller exists for the view folder, it will make a new instance of that controller and render in that instance.

4. component
Next, all folders under app/ are checked.  The view path looked for is {component}/index/index.html with a section of :body.

5. gems
Lastly the app folder of all gems that start with volt are checked.  They are checked for a similar path to component.

When you create a control, you can also specify multiple parts of the search path in the name.  The parts should be separated by a :  Example:

```html
    <:blog:comments />
```

The above would search the following:

| Section   | View File    | View Folder    | Component   |
|-----------|--------------|----------------|-------------|
| :comments | blog.html    |                |             |
| :body     | comments.html| blog           |             |
| :body     | index.html   | comments       | blog        |
| :body     | index.html   | comments       | gems/blog   |

Once the view file for the control or template is found, it will look for a matching controller.  If the control is specified as a local template, an empty ModelController will be used.  If a controller is found and loaded, a corresponding "action" method will be called on it if its exists.  Action methods default to "index" unless the component or template path has two parts, in which case the last part is the action.

# Control Arguments/Attributes

Like other html tags, controls can be passed attributes.  These are then converted into a hash and passed as the first argument to the initialize method on the controller.  The standard ModelController's initialize will then assign each key/value in the attributes hash as instance values.  This makes it easy to access attributes passed in.

```html

<:Body>

  <ul>
    {#each _todos as todo}
      <:todo name="{todo._name}" />
    {/}
  </ul>

<:Todo>
  <li>{@name}</li>

```


# Routes

Routes in Volt are very different from traditional backend frameworks.  Since data is synchronized using websockets, routes are mainly used to serialize the state of the application into the url in a pretty way.  When a page is first loaded, the URL is parsed with the routes and the params model's values are set from the URL.  Later if the params model is updated, the URL is updated based on the routes.

This means that routes in Volt have to be able to go both from URL to params and params to URL.  It should also be noted that if a link is clicked and the controller/view to render the new URL is within the current component (or an included component), the page will not be reloaded, the URL will be updated with the HTML5 history API, and the params hash will reflect the new URL.  You can use the changes in params to render different views based on the URL.

## Routes file

Routes are specified on a per-component basis in the config/routes.rb file.  Routes simply map from URL to params.

```ruby
    get "/todos", {_view: 'todos'}
```

Routes take two arguments; a path, and a params hash.  When a new URL is loaded and the path is matched on a route, the params will be set to the params provided for that route.  The specified params hash acts as a constraint.  An empty hash will match any url.  Any params that are not matched will be placed in the query parameters.

When the params are changed, the URL will be set to the path for the route whose params hash matches.

Route paths can also contain variables similar to bindings:

```ruby
    get "/todos/{_index}", _view: 'todos'
```

In the case above, if any URL matches /todos/*, (where * is anything but a slash), it will be the active route. ```params._view``` would be set to 'todos', and ```params._index``` would be set to the value in the path.

If ```params._view``` were 'todos' and ```params._index``` were not nil, the route would be matched.

Routes are matched top to bottom in a routes file.

## Debugging

An in browser irb is in the works.  We also have source maps support, but they are currently disabled by default.  To enable them run:

    MAPS=true volt s

This feature is disabled by default because (due to the volume of pages rendered) it slows down page rendering. We're working with the opal and sprockets teams to make it so everything is still served in one big source maps file (which would show the files as they originated on disk)


## Channel

Controllers provide a `#channel` method, that you can use to get the status of the connection to the backend.  Channel is provided in a ReactiveValue, and when the status changes, the changed events are triggered.  It provides the following:

| method      | description                                               |
|-------------|-----------------------------------------------------------|
| connected?  | true if it is connected to the backend                    |
| status      | possible values: :opening, :open, :closed, :reconnecting  |
| error       | the error message for the last failed connection          |
| retry_count | the number of reconnection attempts that have been made without a successful connection |
| reconnect_interval | the time until the next reconnection attempt (in seconds) |


# Testing

** Testing is being reworked at the moment.
Volt provides rspec and capybara out of the box.  You can test directly against your models, controllers, etc... or you can do full integration tests via [Capybara](https://github.com/jnicklas/capybara).

To run Capybara tests, you need to specify a driver.  The following drivers are currently supported:

1. Phantom (via poltergeist)

```BROWSER=phantom bundle exec rspec```

2. Firefox

```BROWSER=firefox bundle exec rspec```

3. IE - coming soon

Chrome is not supported due to [this issue](https://code.google.com/p/chromedriver/issues/detail?id=887#makechanges) with ChromeDriver.  Feel free to go [here](https://code.google.com/p/chromedriver/issues/detail?id=887#makechanges) and pester the chromedriver team to fix it.

## Accessing DOM section in a controller

TODO


# Data Store

Volt provides a data store collection on the front-end and the back-end.  In store, all plural names are assumed to be collections (like an array), and all singular are assumed to be a model (like a hash).

```ruby
store._things
```

**Work in progress**

| state       | events bound | description                                                  |
|-------------|--------------|--------------------------------------------------------------|
| not_loaded  | no           | no events and no one has accessed the data in the model      |
| loading     | maybe        | someone either accessed the data or bound an event           |
| loaded      | yes          | data is loaded and there is an event bound                   |
| dirty       | no           | data was either accessed without binding an event, or an event was bound, but later unbound. |

# Contributing

You want to contribute?  Great!  Thanks for being awesome!  At the moment, we have a big internal todo list, hop on https://gitter.im/voltrb/volt so we don't duplicate work.  Pull requests are always welcome, but asking about helping on gitter should save some duplication.

[![Pledgie](https://pledgie.com/campaigns/26731.png?skin_name=chrome)](https://pledgie.com/campaigns/26731)
