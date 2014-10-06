require 'volt/models/persistors/base'

module Persistors
  class Params < Base
    def initialize(model)
      @model = model
    end

    def changed(attribute_name)
      if RUBY_PLATFORM == 'opal'
        %x{
          if (window.setTimeout && this.$run_update.bind) {
            if (window.paramsUpdateTimer) {
              clearTimeout(window.paramsUpdateTimer);
            }
            window.paramsUpdateTimer = setTimeout(this.$run_update.bind(this), 0);
          }
        }
      end
    end

    def run_update
      if Volt.client?
        $page.url.update!
      end
    end
  end
end
