# Why Volt?

Volt is a new web framework.  You use Ruby for both your client and server code.  Volt helps you break your code into reusable components.  It handles managing all assets and dependencies for you.  Volt automatically updates your pages for you when your model data changes and sync's that data to the database for you.  By providing reusable structure and handling common tasks, Volt lets you build web app's really fast!

# Features

## Components

Volt projects are broken into components.  Components are easy to create and simple to reuse.  They are easily shared and only require one line of code to insert into your project.  Volt provides many common components out of the box.

## Reactive

Data in volt is reactive by default.  Changes to the data is automatically updated in the DOM.


## Data Syncing

A lot of modern web development is moving data between the front-end to the back-end.  Volt eliminates all of that work.  Model's on the front-end automatically sync to the back-end, and vice versa.  Validations are run on both sides for security.  Models on the front-end are automatically updated whenever they are changed anywhere else (another browser, a background task, etc..)


# Why Volt is Awesome

- only the relevant DOM is updated.  There is no match and patch algorithm to update from strings like other frameworks, all associations are tracked through our reactive core, so we know exactly what needs to be updated without the need to generate any extra HTML.  This has a few advantages, namely that things like input fields are retained, so any properties (focus, tab position, etc...) are also retained.


# Why Ruby

Isomorphic type system with javascript

In web development today, JavaScript gets to be the default language by virtue of being in the browser.  JavaScript is a very good language, but it has a lot of warts.  (See http://wtfjs.com/ for some great examples)  Some of these can introduce bugs, others are just difficult to deal with.  JavaScript was rushed to market quickly and standardized very quickly.  Ruby was used by a small community for years while most of the kinks were worked out.  Ruby also has some great concepts such as [uniform access](http://en.wikipedia.org/wiki/Uniform_access_principle), [mixin's](http://en.wikipedia.org/wiki/Mixin), [duck typing](http://en.wikipedia.org/wiki/Duck_typing), and [blocks](http://yehudakatz.com/2012/01/10/javascript-needs-blocks/) to name a few.  While many of these features can be implemented in JavaScript in userland, few are standardardized and the solutions are seldom eloquent.

[5,10,1].sort()
// [1, 10, 5]

Uniform access and duck typing provides us with the ability to make reactive objects that have the exact same interface as a normal object.  This is a big win, nothing new to learn to do reactive programming.  They can also be used interchangably with regular objects.

# Why Opal

Opal is really an increadiable project, and the core team has done a great job.  Ruby and JavaScript are similar in a lot of ways.  This lets Opal compile to JavaScript that is very readable.  This also means that Opal's performance is great.  You'll find that in most cases Ruby code runs with no performance penality compared to the eqivilent JavaScript code.
