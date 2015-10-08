# See https://github.com/voltrb/volt#routes for more info on routes

client '/bindings/{{ route_test }}', action: 'bindings'
client '/bindings', action: 'bindings'
client '/form', action: 'form'
client '/store', action: 'store_demo'
client '/cookie_test', action: 'cookie_test'
client '/flash', action: 'flash'
client '/yield', action: 'yield'
client '/first_last', action: 'first_last'
client '/todos', controller: 'todos'
client '/html_safe', action: 'html_safe'
client '/missing', action: 'missing'
client '/require_test', action: 'require_test'
client '/images', action: 'images'
client '/login_from_task', action: 'login_from_task'
client '/callbacks', action: 'callbacks'

# Events
client '/events', component: 'main', controller: 'events', action: 'index'

client '/save', component: 'main', controller: 'save', action: 'index'

# Signup/login routes
client '/signup', component: 'user_templates', controller: 'signup'
client '/login', component: 'user_templates', controller: 'login'

# HTTP endpoints
get '/simple_http', controller: 'simple_http', action: 'index'
get '/simple_http/store', controller: 'simple_http', action: 'show'
post '/simple_http/upload', controller: 'simple_http', action: 'upload'

# Route for file uploads
client '/upload', controller: 'upload', action: 'index'

# The main route, this should be last.  It will match any params not previously matched.
client '/', {}
