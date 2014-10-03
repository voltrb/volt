# See https://github.com/voltrb/volt#routes for more info on routes

get "/bindings/{_route_test}", _action: 'bindings'
get "/bindings", _action: 'bindings'
get "/store", _action: 'store'

# The main route, this should be last.  It will match any params not previously matched.
get '/', {}