# A dom template is used to optimize going from a template name to
# dom nodes and bindings.  It stores a copy of the template's parsed
# dom nodes, then when a new instance is requested, it updates the
# dom markers (comments) for new binding numbers and returns a cloneNode'd
# version of the dom nodes and the bindings.

class DomTemplate

end