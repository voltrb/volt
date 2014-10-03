require 'volt/extra_core/log'
require 'volt/extra_core/array'
require 'volt/extra_core/object'
require 'volt/extra_core/blank'
require 'volt/extra_core/stringify_keys'
require 'volt/extra_core/string'
require 'volt/extra_core/numeric'
require 'volt/extra_core/true_false'
if RUBY_PLATFORM == 'opal'
  # TODO: != does not work with opal for some reason
else
  require 'volt/extra_core/symbol'
end
