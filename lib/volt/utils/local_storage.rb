module Volt
  module LocalStorage
    extend HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `localStorage`
      end
    end
  end
end
