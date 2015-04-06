# See https://github.com/voltrb/volt#routes for more info on routes

client '/about', action: 'about'

# Routes for login and signup, provided by user-templates component gem
client '/signup', controller: 'user-templates', action: 'signup'
client '/login', controller: 'user-templates', action: 'login'

# The main route, this should be last. It will match any params not
# previously matched.
client '/', {}
