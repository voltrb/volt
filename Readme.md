[![Gem Version](https://badge.fury.io/rb/volt.png)](http://badge.fury.io/rb/volt)
[![Code Climate](https://codeclimate.com/github/voltrb/volt.png)](https://codeclimate.com/github/voltrb/volt)

# Volt

NOTE: VOLT IS STILL IN DEVELOPMENT, DON'T USE IT FOR ANYTHING SERIOUS YET

Volt is a ruby web framework where your ruby code runs on both the server and the client (via [opal](https://github.com/opal/opal).)  The dom automatically update as the user interacts with the page.  Page state can be stored in the url, if the user hits a url directly, the HTML will first be rendered on the server for faster load times and easier indexing by search engines.

Instead of syncing data between the client and server via HTTP, volt uses a persistent connection between the client and server.  When data updated on one client, it is updated in the database and any other listening clients.  (With almost no setup code needed)

Pages HTML is written in a handlebars like template language.  Volt uses data flow/reactive programming to automatically and intellegently propigate changes to the dom (or anything other code wanting to know when a value updates)  When something in the dom changes, Volt intellegent updates only the nodes that need to be changed.

## Goals

Volt has the following goals:

1. Developer happieness
2. Write once on the client and the server
3. Automatic data syncing between client and server
4. Apps are built as nested components.  Components can be shared (via gems)
5. Concurrent.  Volt provides tools to simplify concurrency.  Component rendering is done in parallel on the server.
6. Intellegent asset management
7. Secure (shouldn't need to be said, but it does)
8. Be fast/light
9. Understandable code base
10. Control Upgradeability

# VOLT guide

This guide will take you through creating a basic web application in Volt.  This tutorial assumes a basic knowledge of ruby and web development.

To get started, install volt:

    gem install volt

Then create a new project:

    volt new project_name
    
This will setup a basic project.  Now lets run the server.

    volt server

You can access the volt console with:

    volt console

# Guide Sections

1. [Rendering](#rendering)
  1. [Reactive Values](#reactive-values)
  2. [Bindings](#bindings)
    1. [Content Binding](#content-binding)
    2. [If Binding](#if-binding)
    3. [Each Binding](#each-binding)
    4. [Attribute Bindings](#attribute-bindings)
2. [Models](#models)
3. [Components](#components)
4. [Controls](#controls)
5. [Routes](#routes)
  1. [Routes file](#routes-file)


# Rendering

When a user interacts with a web page, typically we want to do two things:

1. Change application state
2. Update the DOM

For example when a user clicks to add a new todo item to a todo list, we might create a JavaScript object to represent the todo item, then add an item to the list's DOM.  A lot of work needs to be done to make sure that the JavaScript object and the DOM always stay in sync.

Recently the idea of "reactive programming" has been used to simplify maintaining the DOM.  The idea is instead of having event handlers that manage a model (or JavaScript object) and manage the DOM, we have event handlers that manage reactive data models.  We describe our DOM layer in a declarative way so that it automatically knows how to render our data models.

## Reactive Value's

To build bindings, Volt provides the ReactiveValue class.  This wraps any object in a reactive interface.  To create a ReactiveValue, simply pass the object you want to wrap as the first argument to new.

```ruby
    a = ReactiveValue.new("my object")
    
    # => @"my object"
```

When .inspect is called on a ReactiveValue (like in the console), an @ is placed infront of the value's inspect string, so you know its reactive.

When you call a method on a ReactiveValue, you get back a new reactive value that depends on the previous one.  It remebers how it was created and you can call .cur on it any time to get its current value, which will be computed based off of the first reactive value.  (Keep in mind below that + is a method call, the same as a.+(b) in ruby.)

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

This provides the backbone for reactive programming.  We setup computation/flow graphs instead of doing an actual calcuation.  Calling .cur (or .inspect, .to_s, etc..) runs the computation and returns the current value at that time, based on all of its dependencies.

ReactiveValue's also let you setup listeners and trigger events:

```ruby
    a = ReactiveValue.new(0)
    a.on('changed') { puts "A changed" }
    a.trigger!('changed')
    # => A Changed
```

These events propigate to any reactive value's created off of a reactive value.

```ruby
    a = ReactiveValue.new(1)
    b = a + 5
    b.on('changed') { puts "B changed" }
    
    a.trigger!('changed')
    # => B changed
```

This event flow lets us know when an object has changed, so we can update everything that depended on that object.

Lastly, we can also pass in other reactive value's as arguments to methods on a reactive value.  The dependencies will be tracked for both and events will propigate down from both.  (Also, note that doing .cur = to update the current value triggers a "changed" event.)

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

### Truthy Checks: .true?, .false?, .or, and .and

Because a method on a reactive value always returns another reactive value, and because only nil and false are false in ruby, we need a way to check if a ReactiveValue is truthy in our code.  The easiest way to do this is by calling .true? on it.  It will return a non-wrapped boolean.  .nil? and .false? do as you would expect.

One common place we use a truthy check is in setting up default values with || (logical or)  Volt provides a convience method that does the same thing .or, but works with ReactiveValue's.

Instead of 

```ruby
    a || b
```

Simply use:
    
```ruby
    a.or(b)
```

.and works the same way as &&.  #and and #or let you maintain the reactivity all of the way through.


### With



## Bindings

Now that you understand the basics of ReactiveValue's, we can discuss bindings.  In Volt, you code your views in a handlebar's like template language.  Volt provides severial bindings, which handle rendering of something for you.  Content bindings are anything inbetween { and }

### Content binding

The most basic binding is a content binding:

    <p>{some_method}<p>

The content binding runs the ruby code between { and }, then renders the return value.  If the returned value is a ReactiveValue, it will update the value updated whenever a 'changed' event is called.

### If binding

An if binding lets you provide basic flow control.

    {#if _some_check?}
      <p>render this</p>
    {/}
    
Blocks are closed with a {/}

When the #if binding is rendered, it will run the ruby code after #if.  If the code is true it will render the code below.  Again, if the returned value is reactive, it will update as that value changes.

If bindings can also have #elsif and #else blocks.

    {#if _condition_1?}
      <p>condition 1 true</p>
    {#elsif _condition_2?}
      <p>condition 2 true</p>
    {#else}
      <p>neither true</p>
    {/}

### Each binding

For iteration over objects, the each binding is provided.

    {#each _items as item}
      <p>{item}</p>
    {/}

Above, if _items was an array, the block would be rendered for each item, setting 'item' to the value of the array element.

You can also access the position of the item in the array with the #index method.

    {#each _items as item}
      <p>{index}. {item}</p>
    {/}

For the array: ['one', 'two', 'three'] this would print:

    0. one
    1. two
    2. three

You can do {index + 1} to correct the numbers.

When items are removed or added to the array, the #each binding automatically and intellegently add or removes the items from/to the dom.

## Attribute Bindings

Bindings can also be placed inside of attributes.

    <p class="{#if _is_cool?}cool{/}">Text</p>

There are some special features provided to make for elements work as "two way bindings"

    <input type="text" value="{_name}" />
    
In the example above, if _name changes, the field will update and if the field is updated, _name will be changed.

    <input type="checkbox" checked="{_checked}" />

If the value of a checked attribute is true, the checkbox will be shown checked.  If it is checked/unchecked, the value will be updated to true or false.

-- TODO: select boxes

If you have a controller at app/home/controller/index_controller.rb, and a view at app/home/views/index/index.html, all methods called are called on the controller.

# Models

Volt's concept of a model is slightly different from many frameworks where a model is the name for the ORM to the database.  In Volt a model is a class where you can store data easily.  Where that data stored is not the concern of the model, but the class that created the model.  Lets first see how to use a model.

Volt comes with many built-in models, one is called 'page'.  If you call #page on a controller, you will get access to the model.  Models provided by Volt are automatically wrapped in a ReactiveValue.

```ruby
    page._name = 'Ryan'
    page._name
    # => @'Ryan'
```
    
Models act like a hash that you can access with getters and setters that start with an _  Prefixing with an underscore makes sure we don't accidentally try to call a method that doesn't exist and get back nil.  There is no need to define which fields a model has, they act similar to a hash, but with a shorter access and assign syntax.

Models also let you nest data:

```ruby
    page._settings._color = 'blue'
    page._settings._color
    # => @'blue'
    
    page._settings
    # => @#<Model:_settings {:_color=>"blue"}>
```
    
Nested data is automatically setup when assigned.  In this case, page._settings is a model that is part of the page model.

You can also append to a model if its not defined yet.

```ruby
    page._items << 'item 1'
    page._items
    # => @#<ArrayModel ["item 1", "item 2"]>
    
    page._items[0]
    # => @"item 1"
```

An array model will automatically be setup to contain the items appended.

Above I mentioned that Volt comes with many different models accessable from a controller.  Each stores in a different location.

| Name      | Storage Location                                                          |
|-----------|---------------------------------------------------------------------------|
| page      | page provides a temporary store that only lasts for the life of the page. |
| store     | store syncs the data to the backend database and provides query methods.  |
| session   | values will be stored in a session cookie.                                |
| params    | values will be stored in the params and url.  Routes can be setup to change how params are shown in the url.  (See routes for more info) |
| controller| a model for the current controller                                        |

**more storage locations are planned**

## Reactive Models

Because all models provided by Volt are wrapped in a ReactiveValue, you can register listeners on them and be updated when values change.  You can also call methods on their values and get updates when the source's change.  Bindings also setup listeners.  Models should be the main place you store all data in Volt.  While you can use ReactiveValue's manually, most of the time you will want to just use something like the page model.

# Components

Apps are made up of Components.  Each folder under app/ is a component.  When you visit a route, it loads all of the files in the component on the front end, so new pages within the component can be rendered on the front end.  If a url is visited that routes to a different component, the request will be loaded as a normal page load and all of that components files will be loaded.  You can think of components as the "reload boundry" between sections of your app.

You can also use controls (see below) from one component in another.  To do this, you must require the component from the component you wish to use them.  This can be done in the ```config/dependencies.rb``` file.  Just put

```ruby
component 'component_name'
```

in the file.

Dependencies act just like require in ruby, but for whole components.

## Component Generator

Components can easily be shared as a gem.  Volt provides a scaffold for component gems.  In a folder (not in a volt project), simply type: volt component {component_name}  This will create the files needed for the gem.  Note that all volt component gems will be prefixed with volt- so they can easily be found by others.

While developing, you can use the component by placing the following in your Gemfile:

    gem 'volt-{component_name}', path: '/path/to/folder/with/component'

Once the gem is ready, you can release it to ruby gems with:

    rake release

Remove the path: option in the gemfile if you wish to use the rubygems version.

# Controls

Everyone wishes that we could predict the scope and required features for each part of our application, but in the real world, things we don't expect to grow large often do and things we think will be large don't end up that way.  Controls let you quickly setup reusable code/views.  The location of the control's code can be moved as it grows without changing the way controls are invoked.

To render a control, simply use a tag like so:

```html
    <:control-name />
```
    
or

```html
    <:control-name></:control-name>
```

To find the control's views and optional controller, Volt will search the following (in order):


| Component   | View Folder    | View File    | Section   |
|-------------|----------------|--------------|-----------|
|             |                |              | :{name}   |
|             |                | {name}.html  | :body     |
|             | {name}         | index.html   | :body     |
| {name}      | index          | index.html   | :body     |
| gems/{name} | index          | index.html   | :body     |

**Note that anything with a view folder will also load a controller if the name/folder matches.**


Each part is explained below:

1. section
Views are composed of sections.  Sections start with a ```<:SectionName>``` tag and end with ```</:SectionName>```  Volt will look first for a section in the same view.

2. views
Next Volt will look for a view file that with the control name.  If found, it will render the body section of that view.

3. view folder
Failing above, Volt will look for a view folder with the control name, and an index.html file within that folder.  It will render the :body section of that view.  If a controller exists for the view folder, it will make a new instance of that controller and render in that instance.

4. component
Next, all folders under app/ are checked.  The view path looked for is {component}/index/index.html with a section of :body.

5. gems
Lastly the app folder of all gems that start with volt are checked.  They are checekd for a similar path to component.

When you create a control, you can also specify multiple parts of the search path in the name.  The parts should be seperated by a :  Example:

```html
    <:blog:comments />
```
    
The above would search the following:

| Component   | View Folder    | View File    | Section   |
|-------------|----------------|--------------|-----------|
|             |                | blog.html    | :comments |
|             | blog           | comments.html| :body     |
| blog        | comments       | index.html   | :body     |
| gems/blog   | comments       | index.html   | :body     |


# Routes

Routes in Volt are very different from traditional backend frameworks.  Since data is synchronized using websockets, routes are mainly used to serialize the state of the application in a pretty way.  When a page is first loaded, the url is parsed with the routes and the params model's values are set from the url.  Later if the params model is updated, the url is updated based on the routes.

This means that routes in volt have to go both from url to params and params to url.  It should also be noted that if a link is clicked and the controller/view to render the new url is within the current component (or an included component), the page will not be reloaded, the url will be updated with the HTML5 history API, and the params hash will reflect the new url.  You can use the changes in params to render different views based on the url.

## Routes file

Routes are specified on a per-component basis in the config/routes.rb file.  Routes simply map from url to params.

    get "/todos", _controller: 'todos'

Routes take two arguments, a path, and a params hash.  When a new url is loaded and the path is matched on a route, the params will be set to the params provided for that route.

When the params are changed, the url will be set to the path for the route that's params hash matches.

**Note: at the moment nested params do not work, but they are a planned feature**

Route path's can also contain variables similar to bindings.

    get "/todos/{_index}", _controller: 'todos'
    
In the case above, if any url matches /todos/*, (where * is anything but a slash), it will be the active route. params._controller would be set to 'todos', and params._index would be set to the value in the path.

If params._controller is 'todos' and params._index is not nil, the route would be matched.

Routes are matched top to bottom in a routes file.