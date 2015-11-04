module Volt
  module SessionStorage
    include HtmlStorage

    def self.area
      `sessionStorage`
    end
  end
end
