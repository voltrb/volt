require 'volt/models'
require 'volt/server/rack/component_paths'

if RUBY_PLATFORM == 'opal'
  require 'volt'
else
  require 'volt/page/page'
end
require 'volt/volt/app'

module Volt
  def self.boot(app_path, additional_paths=[])
    # Boot the app
    App.new(app_path, additional_paths)
  end


end