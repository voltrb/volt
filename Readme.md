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
10. Component Upgradeability

## 10. Component Upgradeability

(seamless promotion)
Everyone wishes that we could predict the scope and required features for each part of our application, but in the real world, things we don't expect to grow large often do and things we think will be large don't end up that way.  Volt provides an easy way to promote sections of html and code to provide more

- subtemplate
- template
- controller
- component