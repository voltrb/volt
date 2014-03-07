require 'volt'

# The Routes class takes a set of routes and sets up methods to go from
# a url to params, and params to url.
# routes do
#   get "/about", _view: 'about'
#   get "/blog/{_id}/edit", _view: 'blog/edit', _action: 'edit'
#   get "/blog/{_id}", _view: 'blog/show', _action: 'show'
#   get "/blog", _view: 'blog'
#   get "/blog/new", _view: 'blog/new', _action: 'new'
#   get "/cool/{_name}", _view: 'cool'
# end
#
# Using the routes above, we would generate the following:
#
# @direct_routes = {
#   '/about' => {_view: 'about'},
#   '/blog' => {_view: 'blog'}
#   '/blog/new' => {_view: 'blog/new', _action: 'new'}
# }
#
# -- nil represents a terminal
# -- * represents any match
# -- a number for a parameter means use the value in that number section
#
# @indirect_routes = {
#     '*' => {
#       'edit' => {
#         nil => {_id: 1, _view: 'blog/edit', _action: 'edit'}
#       }
#       nil => {_id: 1, _view: 'blog/show', _action: 'show'}
#     }
#   }
# }
#
# Match for params
@param_matches = [
  {_id: nil, _view: 'blog/edit', _action: 'edit'}
]

class Routes
  def initialize
    # Paths where there are no bindings (an optimization)
    @direct_routes = {}

    # Paths with bindings
    @indirect_routes = {}

    #
  end

  def define(&block)
    instance_eval(&block)

    return self
  end

  # Add a route
  def get(path, params={})
    params = params.symbolize_keys
    if has_binding?(path)
      add_indirect_path(path, params)
    else
      @direct_routes[path] = params
    end
  end

  # Check if a string has a binding in it
  def has_binding?(string)
    string.index('{') && string.index('}')
  end

  # Build up the @indirect_routes data structure.
  # '*' means wildcard match anything
  # nil means a terminal, who's value will be the params.
  #
  # In the params, an integer vaule means the index of the wildcard
  def add_indirect_path(path, params)
    node = @indirect_routes

    parts = url_parts(path)

    parts.each_with_index do |part, index|
      if has_binding?(part)
        params[part[1..-2].to_sym] = index

        # Set the part to be '*' (anything matcher)
        part = '*'
      end

      node = (node[part] ||= {})
    end

    node[nil] = params
  end

  # Takes in params and generates a path and the remaining params
  # that should be shown in the url.  The extra "unused" params
  # will be tacked onto the end of the url ?param1=value1, etc...
  #
  # returns the url and new params
  def params_to_url(params)


    return '/', params
  end

  # Takes in a path and returns the matching params.
  # returns params as a hash
  def url_to_params(path)
    # First try a direct match
    result = @direct_routes[path]
    return result if result

    # Next, split the url and walk the sections
    parts = url_parts(path)

    return match_path(parts, parts, @indirect_routes)
  end

  private
    # Recursively walk the @indirect_routes hash, return the params for a route, return
    # false for non-matches.
    def match_path(original_parts, remaining_parts, node)
      # Take off the top part and get the rest into a new array
      # part will be nil if we are out of parts (fancy how that works out, now
      # stand in wonder about how much someone thought this through, though
      # really I just got lucky)
      part, *parts = remaining_parts

      if part == nil
        if node[part]
          # We found a match, replace the bindings and return
          # TODO: Handle nested
          return setup_bindings_in_params(original_parts, node[part])
        else
          return false
        end
      elsif (new_node = node[part])
        # Direct match, continue
        return match_path(original_parts, parts, new_node)
      elsif (new_node = node['*'])
        return match_path(original_parts, parts, new_node)
      end
    end

    # The params out of match_path will have integers in the params that came from bindings
    # in the url.  This replaces those with the values from the url.
    def setup_bindings_in_params(original_parts, params)
      params.each_pair do |key, value|
        if value.is_a?(Fixnum)
          # Lookup the param's value in the original url parts
          params[key] = original_parts[value]
        end
      end

      return params
    end


    def url_parts(path)
      return path.split('/').reject(&:blank?)
    end
end
