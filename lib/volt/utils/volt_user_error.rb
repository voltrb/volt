# VoltUserError is a base class for Volt errors that you don't need backtraces on.
# These are errors that you simply need to communicate something to developer with.
class VoltUserError < RuntimeError
end
