# FAQ

## How do I include/call JavaScript from Volt?

1. If you have a url outside of your project you want to include with a component, see dependencies under https://github.com/voltrb/volt/blob/master/Readme.md#Dependencies. This is useful for including assets from a shared CDN and will place a script tag on the page.
2. You can also place script tags in public/index.html (though it's better to put them in the components). Any JS files in app/{component_name}/assets/js will be loaded automatically.
3. Lastly, you can also embed javascript inline in any controllers since they run in opal (see opalrb.org for info on that)
