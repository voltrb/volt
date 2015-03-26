# See https://github.com/voltrb/volt#routes for more info on routes

get '/bindings/{{ route_test }}', action: 'bindings'
get '/bindings', action: 'bindings'
get '/store', action: 'store'
get '/cookie_test', action: 'cookie_test'
get '/flash', action: 'flash'
get '/yield', action: 'yield'
get '/todos', controller: 'todos'

# Signup/login routes
get '/signup', controller: 'user-templates', action: 'signup'
get '/login', controller: 'user-templates', action: 'login'

# The main route, this should be last.  It will match any params not previously matched.
get '/', {}
