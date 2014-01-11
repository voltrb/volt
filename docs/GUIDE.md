# VOLT guide

This guide will take you through creating a basic web application in Volt.  This tutorial assumes a basic knowledge of ruby and web development.

To get started, install volt:

    gem install volt

Then create a new project:

    volt new project_name
    
This will setup a basic project.  Now lets run the server.

    volt server


## Bindings

When a user interacts with a web page, typically we want to do two things:

1. Change application state
2. Update the DOM

For example when a user clicks to add a new todo item to a todo list, we might create a JavaScript object to represent the todo item, then add an item to the list's DOM.  A lot of work needs to be done to make sure that the JavaScript object and the DOM always stay in sync.

Recently the idea of "reactive programming" has been used to simplify maintaining the DOM.  The idea is instead of having event handlers that manage a model (or JavaScript object) and manage the DOM, we have event handlers that manage reactive data models.  We describe our DOM layer in a declaritive way so that it automatically knows how to render our data models.



## Components

Apps are broken up into components.  Each folder under app/ represents a component.  You can think of components like a single page app.  When a page within a component is loaded, all the controllers, models, and views within a component are loaded on the front end.  The initial page load will be rendered on the backend for quick loading, then any future updates will be rendered on the front end.