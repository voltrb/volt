require 'volt/models/persistors/base'

module Volt
  module Persistors
    class Params < Base
      def changed(attribute_name)
        if RUBY_PLATFORM == 'opal'
          `
            if (window.setTimeout && this.$run_update.bind) {
              if (window.paramsUpdateTimer) {
                clearTimeout(window.paramsUpdateTimer);
              }
              window.paramsUpdateTimer = setTimeout(this.$run_update.bind(this), 0);
            }
          `

        end

        true
      end

      def run_update
        Volt.current_app.url.update! if Volt.client?
      end
    end
  end
end
