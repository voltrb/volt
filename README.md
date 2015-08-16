[![Pledgie](https://pledgie.com/campaigns/26731.png?skin_name=chrome)](https://pledgie.com/campaigns/26731)
[![Gem Version](https://badge.fury.io/rb/volt.svg)](http://badge.fury.io/rb/volt)
[![Code Climate](https://codeclimate.com/github/voltrb/volt/badges/gpa.svg)](https://codeclimate.com/github/voltrb/volt)
[![Coverage Status](https://coveralls.io/repos/voltrb/volt/badge.svg?branch=master)](https://coveralls.io/r/voltrb/volt?branch=master)[![Build Status](http://img.shields.io/travis/voltrb/volt/master.svg?style=flat)](https://travis-ci.org/voltrb/volt)
[![Inline docs](http://inch-ci.org/github/voltrb/volt.svg?branch=master)](http://inch-ci.org/github/voltrb/volt)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square)](http://opensource.org/licenses/MIT)

For the current status of Volt, read: http://voltframework.com/blog

Volt is a Ruby web framework where your Ruby code runs on both the server and the client (via [Opal](https://github.com/opal/opal)). The DOM automatically updates as the user interacts with the page. Page state can be stored in the URL. If the user hits a URL directly, the HTML will first be rendered on the server for faster load times and easier indexing by search engines.  Subsequent local page interactions will be rendered on the client.

Instead of syncing data between the client and server via HTTP, Volt uses a persistent connection between the client and server. When data is updated on one client, it is updated in the database and any other listening clients (with almost no setup code needed).

Page HTML is written in a templating language where you can put Ruby between `{{` and `}}`. Volt uses data flow/reactive programming to automatically and intelligently propagate changes to the DOM (or to any other code that wants to know when a value has changed). When something in the DOM changes, Volt intelligently updates only the DOM nodes that need to be changed.

See some demo videos here:
- [Volt Todos Example](https://www.youtube.com/watch?v=KbFtIt7-ge8)
- [What Is Volt in 6 Minutes](https://www.youtube.com/watch?v=P27EPQ4ne7o)
- [Promises in 0.9.3 prerelease](https://www.youtube.com/watch?v=1RX9i8ivtWI)
- [Pagination Example](https://www.youtube.com/watch?v=1uanfzMLP9g)
- [Routes and Templates](https://www.youtube.com/watch?v=1yNMP3XR6jU)
- [Isomorphic App Development - RubyConf 2014](https://www.youtube.com/watch?v=7i6AL7Walc4)
- [Build a Blog with Volt](https://www.youtube.com/watch?v=c478sMlhx1o)
**Note:** The blog video is outdated, expect an updated version soon.

Check out demo apps:
 - https://github.com/voltrb/todomvc
 - https://github.com/voltrb/blog5

# Docs

Read the [full docs on Volt here](http://voltframework.com/docs)

There is also a [work in progress tutorial](https://github.com/rhgraysonii/volt_tutorial) by @rhgraysonii

# More Videos

Rick Carlino has been putting together some [great volt tutorial videos](http://datamelon.io/blog) also.

 - [Volt URL Routing](http://datamelon.io/blog/2015/routes-and-multi-view-apps.html)
 - [Volt Tasks](http://datamelon.io/blog/2015/creating-volt-task-objects.html)
 - [Volt Views](http://datamelon.io/blog/2015/understanding-views-in-volt-with-a-card-game.html)
 - [Volt Permissions](http://datamelon.io/blog/2015/twitter-clone-demonstrates-volt-permissions.html)
 - [Volt Runners](http://datamelon.io/blog/2015/automation-of-everything-with-volt-runners.html)
 - [Volt Components](http://datamelon.io/blog/2015/staying-productive-with-the-volt-component-ecosystem.html)
 - [REST APIs in Volt](http://datamelon.io/blog/2015/building-rest-apis-with-volt.html)
 - [Javascript Library Interop](http://datamelon.io/blog/2015/using-js-libraries-with-opal.html)
 - [Credit Card Payments with Volt](http://datamelon.io/blog/2015/payment-form-using-volt-and-stripe.html)
 - [Build a Realtime Chat App](http://datamelon.io/blog/2015/building-a-chat-app-in-volt.html)
 - [6 Key Concepts for New Volt Learners](http://datamelon.io/blog/2015/6-concepts-for-volt-beginners.html)

@ahnbizcad maintains a [playlist of Volt related videos](https://www.youtube.com/watch?v=McxtO8ybxy8&list=PLmQFeDKFCPXatHb-zEXwfeMH01DPiZjP7).

# Getting Help

Have a question and need help?  The volt team watches [stackoverflow](http://stackoverflow.com/search?q=voltrb) for questions and will get back to you quickly.  Be sure to post the question with the #voltrb tag.  If you have something you'd like to discuss, drop into our [gitter room](https://gitter.im/voltrb/volt).

# Contributing

You want to contribute? Great! Thanks for being awesome! At the moment, we have a big internal todo list.  Please hop on https://gitter.im/voltrb/volt so that we don't duplicate work. Pull requests are always welcome, but asking about helping on Gitter should save some duplication.

# Support

VoltFramework is currently a labor of love mainly built by a small group of core developers.  Donations are always welcome and will help Volt get to production faster :-)  Also, if you or your company is interested in sponsoring Volt, please talk to @ryanstout in [gitter](https://gitter.im/voltrb/volt).

[![Pledgie](https://pledgie.com/campaigns/26731.png?skin_name=chrome)](https://pledgie.com/campaigns/26731)

Bitcoins can also be sent to 1AYiL3MiSVe2QFyexzozUvFFH7uGCJgJMZ
