# Collection helpers provide methods to access methods of page directly.
# @page is expected to be defined and a Volt::Page
module Volt
  module CollectionHelpers
    def url_for(params)
      @page.url.url_for(params)
    end

    def url_with(params)
      @page.url.url_with(params)
    end

    def store
      @page.store
    end
  end
end
