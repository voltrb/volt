[![Gem Version](https://badge.fury.io/rb/volt.svg)](http://badge.fury.io/rb/volt)
[![Code Climate](http://img.shields.io/codeclimate/github/voltrb/volt.svg)](https://codeclimate.com/github/voltrb/volt)
[![Build Status](http://img.shields.io/travis/voltrb/volt/master.svg)](https://travis-ci.org/voltrb/volt)
[![Inline docs](http://inch-ci.org/github/voltrb/volt.svg?branch=master)](http://inch-ci.org/github/voltrb/volt)
[![Volt Chat](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/voltrb/volt)

** For the current status of volt, read: http://voltframework.com/blog

# Volt

Volt is a Ruby web framework where your ruby code runs on both the server and the client (via [opal](https://github.com/opal/opal)).  The DOM automatically updates as the user interacts with the page. Page state can be stored in the URL. If the user hits a URL directly, the HTML will first be rendered on the server for faster load times and easier indexing by search engines.

Instead of syncing data between the client and server via HTTP, Volt uses a persistent connection between the client and server. When data is updated on one client, it is updated in the database and any other listening clients (with almost no setup code needed).

Pages HTML is written in a handlebars-like template language.  Volt uses data flow/reactive programming to automatically and intelligently propagate changes to the DOM (or any other code wanting to know when a value updates).  When something in the DOM changes, Volt intelligently updates only the nodes that need to be changed.

See some demo videos here:
** Note: These videos are outdated, new videos coming tomorrow.
 - [Volt Todos Example](https://www.youtube.com/watch?v=6ZIvs0oKnYs)
 - [Build a Blog with Volt](https://www.youtube.com/watch?v=c478sMlhx1o)
 - [Reactive Values in Volt](https://www.youtube.com/watch?v=yZIQ-2irY-Q)

Check out demo apps:
 - https://github.com/voltrb/todos3
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

1. Model read/write permissions
2. User accounts, user collection, signup/login templates

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
  1. [States and Computations](#state-and-computations)
    1. [Computations](#computations)
  2. [Dependencies](#dependencies)
3. [Views](#views)
  1. [Bindings](#bindings)
    1. [Content Binding](#content-binding)
    2. [If Binding](#if-binding)
    3. [Each Binding](#each-binding)
    4. [Attribute Bindings](#attribute-bindings)
  2. [Escaping](#escaping)
4. [Models](#models)
  1. [Nil Models](#nil-models)
  2. [Provided Collections](#provided-collections)
  3. [Store Collection](#store-collection)
  4. [Sub Collections](#sub-collections)
  5. [Model Classes](#model-classes)
  6. [Buffers](#buffers)
  7. [Validations](#validations)
  8. [Model State](#model-state)
  9. [ArrayModel Events](#arraymodel-events)
  10. [Automatic Model Conversion](#automatic-model-conversion)
5. [Controllers](#controllers)
  1. [Reactive Accessors](#reactive-accessors)
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
11. [Debugging](#debugging)
12. [Volt Helpers](#volt-helpers)
  1. [Logging](#logging)
  2. [App Configuration](#app-configuration)
13. [Contributing](#contributing)

# Getting Help

Volt is still a work in progress, but early feedback is appreciated.  Use the following to communicate with the developers, someone will get back to you very quickly:

- **If you need help**: post on [stackoverflow.com](http://www.stackoverflow.com). Be sure to tag your question with `voltrb`.
- **If you found a bug**: post on [github issues](https://github.com/voltrb/volt/issues)
- **If you have an idea or need a feature**: post on [github issues](https://github.com/voltrb/volt/issues)
- **If you want to discuss Volt**: [chat on gitter](https://gitter.im/voltrb/volt), someone from the volt team is usually online and happy to help with anything.


# Rendering

When a user interacts with a web page, typically we want to do two things:

1. Change application state
2. Update the DOM

For example when a user clicks to add a new todo item to a todo list, we might create an object to represent the todo item, then add an item to the list's DOM.  A lot of work needs to be done to make sure that the object and the DOM always stay in sync.

The idea of "reactive programming" can be used to simplify maintaining the DOM.  Instead of having event handlers that manage a model and manage the DOM, we have event handlers that manage reactive data models.  We describe our DOM layer in a declarative way so that it automatically knows how to render our data models.

## State and Computations

Web applications center around maintaining state.  Many events can trigger changes to a state.  Page interaction like entering text into form elements, clicking a button, links, scrolling, etc.. can all change the state of the app.  In the past, each page interaction event would manually change any state stored on a page.

To simplify managing application state, all application state is kept in models that can optionally be persisted in different locations.  By centralizing the application state, we reduce the amount of complex code needed to update a page.  We can then build our page's html declaratively.  The relationship to the page's models' are bound using function and method calls.

We want our DOM to automatically update when our model data changes.  To make this happen, Volt lets you "watch" any method/proc call and have it get called again when data accessed by the method/proc call changes.

### Computations

Lets take a look at this in practice.  We'll use the ```page``` collection as an example.  (You'll see more on collections later)

First, we setup a computation watch.  Computations are built by calling .watch! on a Proc.  Here we'll use the ruby 1.9 proc shorthand syntax ```-> { ... }``` It will run once, then run again each time the data in page._name changes.
```ruby
    page._name = 'Ryan'
    -> { puts page._name }.watch!
    # => Ryan
    page._name = 'Jimmy'
    # => Jimmy
```

Each time page._name is assigned to a new value, the computation is run again.  A re-run of the computation will be triggered when any data accessed in the previous run is changed.  This lets us access data through methods and still have watches re-triggered.

```ruby
    page._first = 'Ryan'
    page._last = 'Stout'

    def lookup_name
      return "#{page._first} #{page._last}"
    end

    -> do
      puts lookup_name
    end.watch!
    # => Ryan Stout

    page._first = 'Jimmy'
    # => Jimmy Stout

    page._last = 'Jones'
    # => Jimmy Jones
```

When you call .watch! the return value is a Computation object.  In the event you no longer want to receive updates, you can call .stop on the computation.

```ruby
    page._name = 'Ryan'

    comp = -> { puts page._name }.watch!
    # => Ryan

    page._name = 'Jimmy'
    # => Jimmy

    comp.stop

    page._name = 'Jo'
    # (nothing)
```

## Dependencies

TODO: Explain Dependencies

As a Volt user, you rarely need to use Comptuations and Dependencies directly.  Instead you usually just interact with models and bindings.  Computations are used under the hood, and having a full understanding of what's going on is useful, but not required.

# Views

Views in Volt use a templating language similar to handlebars. They can be broken up into sections. A section header looks like the following:

```html
<:Body>
```

Section headers should start with a capital letter so as not to be confused with [controls](#controls).  Section headers do not use closing tags.  If section headers are not provided, the Body section is assumed.

Sections help you split up different parts of the same content (title and body usually), but within the same file.

## Bindings

In Volt, you code your views in a handlebars like template language.  Volt provides several bindings, which handle rendering of something for you. Content bindings are anything inbetween {{ and }}.

### Content binding

The most basic binding is a content binding:

```html
    <p>{{ some_method }}<p>
```

The content binding runs the Ruby code between {{ and }}, then renders the return value.  Any time the data a content binding relies on changes, the binding will run again and update the text

### If binding

An if binding lets you provide basic flow control.

```html
    {{ if _some_check? }}
      <p>render this</p>
    {{ end }}
```

Blocks are closed with a {{ end }}

When the if binding is rendered, it will run the ruby code after #if.  If the code is true it will render the code below.  Again, if the returned value is reactive, it will update as that value changes.

If bindings can also have #elsif and #else blocks.

```html
    {{ if _condition_1? }}
      <p>condition 1 true</p>
    {{ elsif _condition_2? }}
      <p>condition 2 true</p>
    {{ else }}
      <p>neither true</p>
    {{ end }}
```

### Each binding

For iteration over objects, you can use .each

```html
    {{ _items.each do |item| }}
      <p>{{ item }}</p>
    {{ end }}
```

Above, if _items were an array, the block would be rendered for each item, setting 'item' to the value of the array element.

You can also access the position of the item in the array with the #index method.

```html
    {{ each _items as item }}
      <p>{{ index }}. {{ item }}</p>
    {{ end }}
```

For the array: ['one', 'two', 'three'] this would print:

    0. one
    1. two
    2. three

You can do {{ index + 1 }} to correct the zero offset.

When items are removed or added to the array, the #each binding automatically and intelligently adds or removes the items from/to the DOM.

### Attribute Bindings

Bindings can also be placed inside of attributes.

```html
    <p class="{{ if _is_cool? }}cool{{ end }}">Text</p>
```

There are some special features provided to make elements work as "two way bindings":

```html
    <input type="text" value="{{ _name }}" />
```

In the example above, if _name changes, the field will update, and if the field is updated, _name will be changed:

```html
    <input type="checkbox" checked="{{ _checked }}" />
```

If the value of a checked attribute is true, the checkbox will be shown checked. If it's checked or unchecked, the value will be updated to true or false.

Radio buttons bind to a checked state as well, except instead of setting the value to true or false, they set it to a supplied field value.

```html
    <input type="radio" checked="{{ _radio }}" value="one" />
    <input type="radio" checked="{{ _radio }}" value="two" />
```

When a radio button is checked, whatever checked is bound to is set to the field's value.  When the checked binding value is changed, any radio buttons where the binding's value matches the fields value are checked.  NOTE: This seems to be the most useful behaviour for radio buttons.

Select boxes can be bound to a value (while not technically a property, this is another convient behavior we add).

```html
  <select value="{{ _rating }}">
    <option value="1">*</option>
    <option value="2">**</option>
    <option value="3">***</option>
    <option value="4">****</option>
    <option value="5">*****</option>
  </select>
```

When the selected option of the select above changes, ```_rating``` is changed to match.  When ```_rating``` is changed, the selected value is changed to the first option with a matching value.  If no matching values are found, the select box is unselected.

If you have a controller at app/home/controller/index_controller.rb, and a view at app/home/views/index/index.html, all methods called are called on the controller.

### Template Bindings

All views/*.html files are templates that can be rendered inside of other views using the template binding.

```html
    {{ template "header" }}
```

## Escaping

When you need to use {{ and }} outside of bindings, anything in a triple mustache will be escaped and not processed as a binding:

```html
    {{{ bindings look like: {{this}}  }}}
```

# Models

Volt's concept of a model is slightly different from many frameworks where a model is the name for the ORM to the database.  In Volt a model is a class where you can store data easily.  Models can be created with a "Persistor", which is responsible for storing the data in the model somewhere.  Models created without a persistor, simply store the data in the classes instance.  Lets first see how to use a model.

Volt comes with many built-in models; one is called `page`.  If you call `#page` on a controller, you will get access to the model.

```ruby
    page._name = 'Ryan'
    page._name
    # => 'Ryan'
```

Models act like a hash that you can access with getters and setters that start with an underscore.  If an attribute is accessed that hasn't yet been assigned, you will get back a "nil model".  Prefixing with an underscore makes sure we don't accidentally try to call a method that doesn't exist and get back nil model instead of raising an exception. Fields behave similarly to a hash, but with a different access and assignment syntax.

  # TODO: Add docs on fields in classes

Models also let you nest data without creating the intermediate models:

```ruby
    page._settings._color = 'blue'
    page._settings._color
    # => @'blue'

    page._settings
    # => @#<Model:_settings {:_color=>"blue"}>
```

Nested data is automatically setup when assigned.  In this case, page._settings is a model that is part of the page model.  This allows nested models to be bound to a binding without the need to setup the model before use.

In Volt models, plural properties return an ArrayModel instance.  ArrayModels behave the same way as normal arrays.  You can add/remove items to the array with normal array methods (#<<, push, append, delete, delete_at, etc...)

```ruby
    page._items
    # #<ArrayModel:70303686333720 []>

    page._items << {_name: 'Item 1'}

    page._items
    # #<ArrayModel:70303686333720 [<Model:70303682055800 {:_name=>"Item 1"}>]>

    page._items.size
    # => 1

    page._items[0]
    # => <Model:70303682055800 {:_name=>"Item 1"}>
```


## Nil Models

As a convience, calling something like ```page._info``` returns what's called a NilModel (assuming it isn't already initialized).  NilModels are place holders for future possible Models.  NilModels allow us to bind deeply nested values without initializing any intermediate values.

```ruby
    page._info
    # => <Model:70260787225140 nil>

    page._info._name
    # => <Model:70260795424200 nil>

    page._info._name = 'Ryan'
    # => <Model:70161625994820 {:_info=><Model:70161633901800 {:_name=>"Ryan"}>}>
```

One gotchya with NilModels is that they are a truthy value (since only nil and false are falsy in ruby).  To make things easier, calling ```.nil?``` on a NilModel will return true.

One common place we use a truthy check is in setting up default values with || (logical or)  Volt provides a convenient method that does the same thing `#or`, but works with NilModels.

Instead of

```ruby
    a || b
```

Simply use:

```ruby
    a.or(b)
```

`#and` works the same way as &&.  #and and #or let you easily deal with default values involving NilModels.

-- TODO: Document .true? / .false?


## Provided Collections

Above, I mentioned that Volt comes with many default collection models accessible from a controller.  Each stores in a different location.

| Name        | Storage Location                                                          |
|-------------|---------------------------------------------------------------------------|
| page        | page provides a temporary store that only lasts for the life of the page. |
| store       | store syncs the data to the backend database and provides query methods.  |
| local_store | values will be stored in the local_store                                  |
| params      | values will be stored in the params and URL.  Routes can be setup to change how params are shown in the URL.  (See routes for more info) |
| flash       | any strings assigned will be shown at the top of the page and cleared as the user navigates between pages. |
| controller  | a model for the current controller                                        |

**more storage locations are planned**

## Store Collection

The store collection backs data in the data store.  Currently the only supported data store is Mongo. (More coming soon, RethinkDb will probably be next)  You can use store very similar to the other collections.

In Volt you can access ```store``` on the front-end and the back-end.  Data will automatically be synced between the front-end and the backend.  Any changes to the data in store will be reflected on any clients using the data (unless a [buffer](#buffer) is in use - see below).

```ruby
    store._items << {_name: 'Item 1'}

    store._items[0]
    # => <Model:70303681865560 {:_name=>"Item 1", :_id=>"e6029396916ed3a4fde84605"}>
```

Inserting into ```store._items``` will create a ```_items``` table and insert the model into it.  An pseudo-unique _id will be automatically generated.

Currently one difference between ```store``` and other collections is ```store``` does not store properties directly.  Only ArrayModels are allowed directly on ```store```

```ruby
    store._something = 'yes'
    # => won't be saved at the moment
```

Note: We're planning to add support for direct ```store``` properties.

## Sub Collections

Models can be nested on ```store```

```ruby
    store._states << {_name: 'Montana'}
    montana = store._states[0]

    montana._cities << {_name: 'Bozeman'}
    montana._cities << {_name: 'Helena'}

    store._states << {_name: 'Idaho'}
    idaho = store._states[1]

    idaho._cities << {_name: 'Boise'}
    idaho._cities << {_name: 'Twin Falls'}

    store._states
    # #<ArrayModel:70129010999880 [<Model:70129010999460 {:_name=>"Montana", :_id=>"e3aa44651ff2e705b8f8319e"}>, <Model:70128997554160 {:_name=>"Montana", :_id=>"9aaf6d2519d654878c6e60c9"}>, <Model:70128997073860 {:_name=>"Idaho", :_id=>"5238883482985760e4cb2341"}>, <Model:70128997554160 {:_name=>"Montana", :_id=>"9aaf6d2519d654878c6e60c9"}>, <Model:70128997073860 {:_name=>"Idaho", :_id=>"5238883482985760e4cb2341"}>]>
```

You can also create a Model first and then insert it.

```ruby
    montana = Model.new({_name: 'Montana'})

    montana._cities << {_name: 'Bozeman'}
    montana._cities << {_name: 'Helena'}

    store._states << montana
```

## Model Classes

By default all collections use the Model class by default.

```ruby
    page._info.class
    # => Model
```

You can provide classes that will be loaded in place of the standard model class.  You can place these in any app/{component}/models folder.  For example, you could add ```app/main/info.rb```  Model classes should inherit from ```Model```

```ruby
    class Info < Model
    end
```

Now when you access any sub-collection called ```_info```, it will load as an instance of ```Info```

```ruby
    page._info.class
    # => Info
```

This lets you set custom methods and validations within collections.

## Buffers

Because the store collection is automatically synced to the backend, any change to a model's property will result in all other clients seeing the change immediately.  Often this is not the desired behavior.  To facilitate building [CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete) apps, Volt provides the concept of a "buffer".  A buffer can be created from one model and will not save data back to its backing model until .save! is called on it.  This lets you create a form thats not saved until a submit button is pressed.

```ruby
    store._items << {_name: 'Item 1'}

    item1 = store._items[0]

    item1_buffer = item1.buffer

    item1_buffer._name = 'Updated Item 1'
    item1_buffer._name
    # => 'Updated Item 1'

    item1._name
    # => 'Item 1'

    item1_buffer.save!

    item1_buffer._name
    # => 'Updated Item 1'

    item1._name
    # => 'Updated Item 1'
```

```#save!``` on buffer also returns a [promise](http://opalrb.org/blog/2014/05/07/promises-in-opal/) that will resolve when the data has been saved back to the server.

```ruby
    item1_buffer.save!.then do
      puts "Item 1 saved"
    end.fail do |err|
      puts "Unable to save because #{err}"
    end
```

Calling .buffer on an existing model will return a buffer for that model instance.  If you call .buffer on an ArrayModel (plural sub-collection), you will get a buffer for a new item in that collection.  Calling .save! will then add the item to that sub-collection as if you had done << to push the item into the collection.

## Validations

Within a model class, you can setup validations.  Validations let you restrict the types of data that can be stored in a model.  Validations are mostly useful for the ```store``` collection, though they can be used elsewhere.

At the moment we only have two validations implemented (length and presence).  Though a lot more will be coming.

```ruby
    class Info < Model
      validate :_name, length: 5
      validate :_state, presence: true
    end
```

When calling save on a model with validations, the following occurs:

1. Client side validations are run; if they fail, the promise from ```save!``` is rejected with the error object.
2. The data is sent to the server and client and server side validations are run on the server; any failures are returned and the promise is rejected on the front-end (with the error object)
    - re-running the validations on the server side makes sure that no data can be saved that doesn't pass the validations
3. If all validations pass, the data is saved to the database and the promise resolved on the client.
4. The data is synced to all other clients.


## Model State

**Work in progress**

| state       | events bound | description                                                  |
|-------------|--------------|--------------------------------------------------------------|
| not_loaded  | no           | no events and no one has accessed the data in the model      |
| loading     | maybe        | someone either accessed the data or bound an event           |
| loaded      | yes          | data is loaded and there is an event bound                   |
| dirty       | no           | data was either accessed without binding an event, or an event was bound, but later unbound. |


## ArrayModel Events

Models trigger events when their data is updated.  Currently, models emit two events: added and removed.  For example:

```ruby
    model = Model.new

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


To convert a Model or an ArrayModel back to a normal hash, call .to_h or .to_a respectively.  To convert them to a JavaScript Object (for passing to some JavaScript code), call `#to_n` (to native).

```ruby
    user = Model.new
    user._name = 'Ryan'
    user._profiles = {
      _twitter: 'http://www.twitter.com/ryanstout',
      _dribbble: 'http://dribbble.com/ryanstout'
    }

    user._profiles.to_h
    # => {_twitter: 'http://www.twitter.com/ryanstout', _dribbble: 'http://dribbble.com/ryanstout'}

    items = ArrayModel.new([1,2,3,4])
    # => #<ArrayModel:70226521081980 [1, 2, 3, 4]>

    items.to_a
    # => [1,2,3,4]
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

When a model is set, any missing methods will be proxied to the model.  This lets you bind within the views without prefixing the model object every time.  It also lets you change out the current model and have the views update automatically.

In methods, the `#model` method returns the current model.

See the [provided collections](#provided-collections) section for a list of the available collection models.

You can also provide your own object to model.

In the example above, any methods not defined on the TodosController will fall through to the provided model.  All views in views/{controller_name} will have this controller as the target for any Ruby run in their bindings.  This means that calls on self (implicit or with self.) will have the model as their target (after calling through the controller).  This lets you add methods to the controller to control how the model is handled, or provide extra methods to the views.

Volt is more similar to an MVVM architecture than an MVC architecture.  Instead of the controllers passing data off to the views, the controllers are the context for the views.  When using a ModelController, the controller automatically forwards all methods it does not handle to the model.  This is convenient since you can set a model in the controller and then access its properties directly with methods in bindings.  This lets you do something like ```{{ _name }}``` instead of something like ```{{ @model._name }}```

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

Like other html tags, controls can be passed attributes.  These are then converted into an object that is passed as the first argument to the initialize method on the controller.  The standard ModelController's initialize will then assign the object to the attrs property which can be accessed with ```#attrs```  This makes it easy to access attributes passed in.

```html

<:Body>

  <ul>
    {{ _todos.each do |todo| }}
      <:todo name="{{ todo._name }}" />
    {{ end }}
  </ul>

<:Todo>
  <li>{{ attrs.name }}</li>
```

Instead of passing in individual attributes, you can also pass in a Model object with the "model" attribute and it will be set as the model for the controller.

```html
<:Body>
  <ul>
    {{ _todos.each do |todo| }}
      <:todo model="{{ todo }}" />
    {{ end }}
  </ul>

<:Todo>
  <li>
    {{ _name }} -
    {{ if _complete }}
      Complete
    {{ end }}
  </li>
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
    get "/todos/{{ _index }}", _view: 'todos'
```

In the case above, if any URL matches /todos/*, (where * is anything but a slash), it will be the active route. ```params._view``` would be set to 'todos', and ```params._index``` would be set to the value in the path.

If ```params._view``` were 'todos' and ```params._index``` were not nil, the route would be matched.

Routes are matched top to bottom in a routes file.

# Channel

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

# Debugging

An in browser irb is in the works.  We also have source maps support, but they are currently disabled by default.  To enable them run:

    MAPS=true volt s

This feature is disabled by default because (due to the volume of pages rendered) it slows down page rendering. We're working with the opal and sprockets teams to make it so everything is still served in one big source maps file (which would show the files as they originated on disk)

# Volt Helpers

## Logging

Volt provides a helper for logging.  Calling ```Volt.logger``` returns an instance of the ruby logger.  See [here](http://www.ruby-doc.org/stdlib-2.1.3/libdoc/logger/rdoc/Logger.html) for more.

```ruby
Volt.logger.info("Some info...")
```

You can change the logger with:

```ruby
Volt.logger = Logger.new
```

## App Configuration

Like many frameworks, Volt changes some default settings based on an environment flag.  You can set the volt environment with the VOLT_ENV environment variable.

All files in the app's ```config``` folder are loaded when Volt boots.  This is similar to the ```initializers``` folder in Rails.

Volt does its best to start with useful defaults.  You can configure things like your database and app name in the config/app.rb file.  The following are the current configuration options:

| name      | default                   | description                                                   |
|-----------|---------------------------|---------------------------------------------------------------|
| app_name  | the current folder name   | This is used internally for things like logging.              |
| db_driver | 'mongo'                   | Currently mongo is the only supported driver, more coming soon|
| db_name   | "#{app_name}_#{Volt.env}  | The name of the mongo database.                               |
| db_host   | 'localhost'               | The hostname for the mongo database.                          |
| db_port   | 27017                     | The port for the mongo database.                              |
| compress_deflate | false              | If true, will run deflate in the app server, its better to let something like nginx do this though |

## Accessing DOM section in a controller

TODO

# Contributing

You want to contribute?  Great!  Thanks for being awesome!  At the moment, we have a big internal todo list, hop on https://gitter.im/voltrb/volt so we don't duplicate work.  Pull requests are always welcome, but asking about helping on gitter should save some duplication.

[![Pledgie](https://pledgie.com/campaigns/26731.png?skin_name=chrome)](https://pledgie.com/campaigns/26731)
