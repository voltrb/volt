# See https://github.com/voltrb/volt#routes for more info on routes

client '/about', action: 'about'

# Routes for login and signup, provided by user-templates component gem
client '/signup', component: 'user-templates', controller: 'signup'
client '/login', component: 'user-templates', controller: 'login'

# The main route, this should be last. It will match any params not
# previously matched.
client '/', {}
