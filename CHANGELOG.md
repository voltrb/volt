# 0.0.8 - Oct 3, 2014

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
