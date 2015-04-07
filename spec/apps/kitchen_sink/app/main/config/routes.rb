# See https://github.com/voltrb/volt#routes for more info on routes

client '/bindings/{{ route_test }}', action: 'bindings'
client '/bindings', action: 'bindings'
client '/store', action: 'store'
client '/cookie_test', action: 'cookie_test'
client '/flash', action: 'flash'
client '/yield', action: 'yield'
client '/todos', controller: 'todos'

# Signup/login routes
client '/signup', component: 'user-templates', controller: 'signup'
client '/login', component: 'user-templates', controller: 'login'

# HTTP endpoints
get '/simple_http', controller: 'simple_http', action: 'index'
get '/simple_http/store', controller: 'simple_http', action: 'show'
post '/simple_http/upload', controller: 'simple_http', action: 'upload'

# Route for file uploads
client '/upload', controller: 'upload', action: 'index'

# The main route, this should be last.  It will match any params not previously matched.
client '/', {}
