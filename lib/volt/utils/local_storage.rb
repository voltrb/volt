module Volt
  module SessionStorage
    include HtmlStorage

    def self.area
      `localStorage`
    end
  end
end
