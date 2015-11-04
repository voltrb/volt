module Volt
  module SessionStorage
    extend HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `sessionStorage`
      end
    end

  end
end
