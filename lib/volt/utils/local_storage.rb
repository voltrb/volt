module Volt
  module SessionStorage
    include HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `localStorage`
      end
    end
  end
end
