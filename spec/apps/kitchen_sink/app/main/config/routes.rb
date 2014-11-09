# See https://github.com/voltrb/volt#routes for more info on routes

get '/bindings/{{_route_test}}', _action: 'bindings'
get '/bindings', _action: 'bindings'
get '/store', _action: 'store'
get '/cookie_test', _action: 'cookie_test'
get '/flash', _action: 'flash'
get '/todos', _controller: 'todos'

# Signup/login routes
get '/signup', _controller: 'user-templates', _action: 'signup'
get '/login', _controller: 'user-templates', _action: 'login'


# The main route, this should be last.  It will match any params not previously matched.
get '/', {}
