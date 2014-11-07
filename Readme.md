[![Gem Version](https://badge.fury.io/rb/volt.svg)](http://badge.fury.io/rb/volt)
[![Code Climate](https://codeclimate.com/github/voltrb/volt/badges/gpa.svg)](https://codeclimate.com/github/voltrb/volt)
[![Build Status](http://img.shields.io/travis/voltrb/volt/master.svg)](https://travis-ci.org/voltrb/volt)
[![Inline docs](http://inch-ci.org/github/voltrb/volt.svg?branch=master)](http://inch-ci.org/github/voltrb/volt)
[![Volt Chat](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/voltrb/volt)
[![Stories in Ready](https://badge.waffle.io/voltrb/volt.png?label=ready&title=Ready)](https://waffle.io/voltrb/volt)

** For the current status of volt, read: http://voltframework.com/blog

# Volt

Volt is a Ruby web framework where your ruby code runs on both the server and the client (via [opal](https://github.com/opal/opal)).  The DOM automatically updates as the user interacts with the page. Page state can be stored in the URL. If the user hits a URL directly, the HTML will first be rendered on the server for faster load times and easier indexing by search engines.

Instead of syncing data between the client and server via HTTP, Volt uses a persistent connection between the client and server. When data is updated on one client, it is updated in the database and any other listening clients (with almost no setup code needed).

Pages HTML is written in a template language where you can put ruby between ```{{``` and ```}}```.  Volt uses data flow/reactive programming to automatically and intelligently propagate changes to the DOM (or any other code wanting to know when a value updates).  When something in the DOM changes, Volt intelligently updates only the nodes that need to be changed.

See some demo videos here:
- [Volt Todos Example](https://www.youtube.com/watch?v=Tg-EtRnMz7o)
- [Pagination Example](https://www.youtube.com/watch?v=1uanfzMLP9g)
- [Build a Blog with Volt](https://www.youtube.com/watch?v=c478sMlhx1o)
** Note: The blog video is outdated, expect an updated version soon.

Check out demo apps:
 - https://github.com/voltrb/todos3
 - https://github.com/voltrb/contactsdemo


# Docs

Read the [full docs on Volt here](http://voltframework.com/docs)

# Contributing

You want to contribute?  Great!  Thanks for being awesome!  At the moment, we have a big internal todo list, hop on https://gitter.im/voltrb/volt so we don't duplicate work.  Pull requests are always welcome, but asking about helping on gitter should save some duplication.

[![Pledgie](https://pledgie.com/campaigns/26731.png?skin_name=chrome)](https://pledgie.com/campaigns/26731)


