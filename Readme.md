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

# Bindings

When a user interacts with a web page, typically we want to do two things:

1. Change application state
2. Update the DOM

For example when a user clicks to add a new todo item to a todo list, we might create a JavaScript object to represent the todo item, then add an item to the list's DOM.  A lot of work needs to be done to make sure that the JavaScript object and the DOM always stay in sync.

Recently the idea of "reactive programming" has been used to simplify maintaining the DOM.  The idea is instead of having event handlers that manage a model (or JavaScript object) and manage the DOM, we have event handlers that manage reactive data models.  We describe our DOM layer in a declaritive way so that it automatically knows how to render our data models.

## Reactive Value's

To build bindings, Volt provides the ReactiveValue class.  This wraps any object in a reactive interface.  To create a ReactiveValue, simply pass the object you want to wrap as the first argument to new.

```ruby
    a = ReactiveValue.new(some_object)
```

When you call a method on a ReactiveValue, you get back a new reactive value that depends on the previous one.  It remebers how it was created and you can call .cur on it any time to get its current value (which will be computed based off of the first reactive value).  Keep in mind below that + is a method call (the same as a.+(b) in ruby.)

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

Lastly, we can also pass in other reactive value's as arguments to methods on a reactive value.  The dependencies will be tracked for both and events will propigate down from both.  Also, doing .cur = to update the current value triggers a "changed" event.

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

# Components

Apps are made up of Components.  Each folder under app/ is a component.  When you visit a route, it loads all of the files in the component on the front end, so new pages within the component can be rendered on the front end.  If a url is visited that routes to a different component, the request will be loaded as a normal page load and all of that components files will be loaded.  You can think of components as the "reload boundry" between sections of your app.

You can also use controls (see below) from one component in another.  To do this, you must require the component from the component you wish to use them.  This can be done in the ```config/dependencies.rb``` file.  Just put

```ruby
component 'component_name'
```

in the file.

Dependencies act just like require in ruby, but for whole components.

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
