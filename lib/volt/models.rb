require 'volt/extra_core/extra_core'
require 'volt/models/model'
require 'volt/models/cursor'
require 'volt/models/persistors/store_factory'
require 'volt/models/persistors/array_store'
require 'volt/models/persistors/model_store'
require 'volt/models/persistors/params'
if RUBY_PLATFORM == 'opal'
  require 'volt/models/persistors/cookies'
end
require 'volt/models/persistors/flash'
require 'volt/models/persistors/local_store'
if RUBY_PLATFORM == 'opal'
  require 'promise'
else
  # Opal doesn't expose its promise library directly
  # gem_dir = Gem::Specification.find_by_name('opal').gem_dir
  require 'opal'

  gem_dir = File.join(Opal.gem_dir, '..')
  require(gem_dir + '/stdlib/promise')
end
# TODO: remove once https://github.com/opal/opal/pull/725 is released.
require 'volt/utils/promise_patch'