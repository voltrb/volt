# See https://github.com/voltrb/volt#routes for more info on routes

client '/bindings/{{ route_test }}', action: 'bindings'
client '/bindings', action: 'bindings'
client '/store', action: 'store'
client '/cookie_test', action: 'cookie_test'
client '/flash', action: 'flash'
client '/yield', action: 'yield'
client '/todos', controller: 'todos'

# Signup/login routes
client '/signup', controller: 'user-templates', action: 'signup'
client '/login', controller: 'user-templates', action: 'login'

#Simple REST endpoint
get '/rest', _controller: 'rest', _action: 'index'

# The main route, this should be last.  It will match any params not previously matched.
client '/', {}
