require 'volt/extra_core/extra_core'
require 'volt/models/model'
require 'volt/models/cursor'
require 'volt/models/persistors/store_factory'
require 'volt/models/persistors/page'
require 'volt/models/persistors/array_store'
require 'volt/models/persistors/model_store'
require 'volt/models/persistors/params'
require 'volt/models/persistors/cookies' if RUBY_PLATFORM == 'opal'
require 'volt/models/persistors/flash'
require 'volt/models/persistors/local_store'
require 'volt/models/root_models/root_models'
# require 'volt/models/root_models/store_root'

# Fow now, we're keeping a volt copy of the promise library from opal 0.8,
# since opal 0.7.x's version has some bugs.
# if RUBY_PLATFORM == 'opal'
#   require 'promise'
# else
#   # Opal doesn't expose its promise library directly
#   require 'opal'

#   gem_dir = File.join(Opal.gem_dir, '..')
#   require(gem_dir + '/stdlib/promise')
# end
# TODO: remove once https://github.com/opal/opal/pull/725 is released.
require 'volt/utils/promise_extensions'
