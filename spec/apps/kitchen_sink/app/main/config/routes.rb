# See https://github.com/voltrb/volt#routes for more info on routes

get '/bindings/{{_route_test}}', _action: 'bindings'
get '/bindings', _action: 'bindings'
get '/store', _action: 'store'
get '/flash', _action: 'flash'
get '/todos', _controller: 'todos'
get '/users_test', _controller: 'users_test'

# The main route, this should be last.  It will match any params not previously matched.
get '/', {}
