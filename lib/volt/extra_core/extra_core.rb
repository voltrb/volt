require 'volt/extra_core/logger'
require 'volt/extra_core/array'
require 'volt/extra_core/object'
require 'volt/extra_core/blank'
require 'volt/extra_core/stringify_keys'
require 'volt/extra_core/string'
require 'volt/extra_core/hash'
require 'volt/extra_core/class'
if RUBY_PLATFORM == 'opal'
  # TODO: != does not work with opal for some reason
  require 'volt/extra_core/timeout'
else
  require 'volt/extra_core/symbol'
end
