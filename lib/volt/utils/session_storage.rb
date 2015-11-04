module Volt
  module SessionStorage
    include HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `sessionStorage`
      end
    end

  end
end
