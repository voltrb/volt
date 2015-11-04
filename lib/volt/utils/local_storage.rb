module Volt
  module LocalStorage
    include HtmlStorage

    if RUBY_PLATFORM == 'opal'
      def self.area
        `localStorage`
      end
    end
  end
end
