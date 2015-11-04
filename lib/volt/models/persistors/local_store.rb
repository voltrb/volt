require 'volt/models/persistors/html_store'
require 'volt/utils/local_storage'

module Volt
  module Persistors
    # Backs a collection in the local store
    class LocalStore < HtmlStore

      def self.storage
        LocalStorage
      end

    end
  end
end
