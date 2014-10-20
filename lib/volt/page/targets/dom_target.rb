require 'volt/page/targets/base_section'
require 'volt/page/targets/dom_section'

module Volt
  # DomTarget's provide an interface that can render bindings into
  # the dom.  Currently only one "dom" is supported, but multiple
  # may be allowed in the future (iframes?)
  class DomTarget < BaseSection
    def dom_section(*args)
      DomSection.new(*args)
    end
  end
end
