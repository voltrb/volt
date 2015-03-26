# See https://github.com/voltrb/volt#routes for more info on routes

get '/about', action: 'about'

# Routes for login and signup, provided by user-templates component gem
get '/signup', controller: 'user-templates', action: 'signup'
get '/login', controller: 'user-templates', action: 'login'

# The main route, this should be last. It will match any params not
# previously matched.
get '/', {}
