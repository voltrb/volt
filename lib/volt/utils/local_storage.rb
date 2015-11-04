require 'volt/utils/html_storage'

module Volt
  class LocalStorage
    extend HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `localStorage`
      end
    end
  end
end
