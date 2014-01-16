require 'volt/page/targets/base_section'
require 'volt/page/targets/dom_section'

# DomTarget's provide an interface that can render bindings into
# the dom.  Currently only one "dom" is supported, but multiple
# may be allowed in the future (iframes?) 
class DomTarget < BaseSection
  def section(*args)
    return DomSection.new(*args)
  end
end