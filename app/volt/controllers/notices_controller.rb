module Volt
  class NoticesController < ModelController
    model :page

    def hey
      "yep"
    end

    def page
      $page.page
    end
  end
end
