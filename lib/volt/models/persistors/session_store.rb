require 'volt/models/persistors/html_store'
require 'volt/utils/session_storage'

module Volt
  module Persistors
    # Backs a collection in the local store
    class SessionStore < HtmlStore

      def self.storage
        SessionStorage
      end

    end
  end
end
