require 'volt/extra_core/extra_core'
require 'volt/models/model'
require 'volt/models/cursor'
require 'volt/models/persistors/store_factory'
require 'volt/models/persistors/array_store'
require 'volt/models/persistors/model_store'
require 'volt/models/persistors/params'
require 'volt/models/persistors/flash'
require 'volt/models/persistors/local_store'
if RUBY_PLATFORM == 'opal'
  require 'promise.rb'
else
  # Opal doesn't expose its promise library directly
  spec = Gem::Specification.find_by_name("opal")
  require(spec.gem_dir + "/stdlib/promise")
end
