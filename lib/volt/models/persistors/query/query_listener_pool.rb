require 'volt/utils/generic_pool'
require 'volt/models/persistors/query/query_listener'

module Volt
  # Keeps track of all query listeners, so they can be reused in different
  # places.  Dynamically generated queries may end up producing the same
  # query in different places.  This makes it so we only need to track a
  # single query at once.  Data updates will only be sent once as well.
  class QueryListenerPool < GenericPool
  end
end
