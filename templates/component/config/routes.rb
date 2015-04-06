# See https://github.com/voltrb/volt#routes for more info on routes

client '/about', action: 'about'

# The main route, this should be last.  It will match any params not previously matched.
client '/', {}
