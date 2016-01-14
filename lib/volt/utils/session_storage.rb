require 'volt/utils/html_storage'

module Volt
  class SessionStorage < HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `sessionStorage`
      end
    end

  end
end
