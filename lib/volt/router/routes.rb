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
# @param_matches = [
#   {_id: nil, _view: 'blog/edit', _action: 'edit'} => Proc.new {|params| "/blog/#{params.id}/edit", params.reject {|k,v| k == :id }}
# ]

class Routes
  def initialize
    # Paths where there are no bindings (an optimization)
    @direct_routes = {}

    # Paths with bindings
    @indirect_routes = {}

    # Matcher for going from params to url
    @param_matches = []
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

    add_param_matcher(path, params)
  end

  # Takes in params and generates a path and the remaining params
  # that should be shown in the url.  The extra "unused" params
  # will be tacked onto the end of the url ?param1=value1, etc...
  #
  # returns the url and new params, or nil, nil if no match is found.
  def params_to_url(test_params)
    @param_matches.each do |param_matcher|
      # TODO: Maybe a deep dup?
      result, new_params = check_params_match(test_params.dup, param_matcher[0])

      if result
        return param_matcher[1].call(new_params)
      end
    end

    return nil, nil
  end

  # Takes in a path and returns the matching params.
  # returns params as a hash
  def url_to_params(path)
    # First try a direct match
    result = @direct_routes[path]
    return result if result

    # Next, split the url and walk the sections
    parts = url_parts(path)

    result = match_path(parts, parts, @indirect_routes)

    return result
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
          # TODO: Handvle nested
          return setup_bindings_in_params(original_parts, node[part])
        else
          return false
        end
      elsif (new_node = node[part])
        # Direct match for section, continue
        return match_path(original_parts, parts, new_node)
      elsif (new_node = node['*'])
        # Match on binding section
        return match_path(original_parts, parts, new_node)
      end
    end

    # The params out of match_path will have integers in the params that came from bindings
    # in the url.  This replaces those with the values from the url.
    def setup_bindings_in_params(original_parts, params)
      # Create a copy of the params we can modify and return
      params = params.dup

      params.each_pair do |key, value|
        if value.is_a?(Fixnum)
          # Lookup the param's value in the original url parts
          params[key] = original_parts[value]
        end
      end

      return params
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
          params[part[2...-2].strip.to_sym] = index

          # Set the part to be '*' (anything matcher)
          part = '*'
        end

        node = (node[part] ||= {})
      end

      node[nil] = params
    end


    def add_param_matcher(path, params)
      params = params.dup
      parts = url_parts(path)

      parts.each_with_index do |part, index|
        if has_binding?(part)
          # Setup a nil param that can match anything, but gets
          # assigned into the url
          params[part[2...-2].strip.to_sym] = nil
        end
      end

      path_transformer = create_path_transformer(parts)

      @param_matches << [params, path_transformer]
    end

    # Takes in url parts and returns a proc that takes in params and returns
    # a url with the bindings filled in, and params with the binding params
    # removed.  (So the remaining can be added onto the end of the url ?params1=...)
    def create_path_transformer(parts)
      return lambda do |input_params|
        input_params = input_params.dup

        url = parts.map do |part|
          val = if has_binding?(part)
            # Get the
            binding = part[2...-2].strip.to_sym
            input_params.delete(binding)
          else
            part
          end

          val
        end.join('/')

        return '/' + url, input_params
      end
    end

    # Takes in a hash of params and checks to make sure keys in param_matcher
    # are in test_params.  Checks for equal value unless value in param_matcher
    # is nil.
    #
    # returns false or true, new_params - where the new params are a the params not
    # used in the basic match.  Later some of these may be inserted into the url.
    def check_params_match(test_params, param_matcher)
      param_matcher.each_pair do |key, value|
        if value.is_a?(Hash)
          if test_params[key]
            result = check_params_match(test_params[key], value)

            if result == false
              return false
            else
              test_params.delete(key)
            end
          else
            # test_params did not have matching key
            return false
          end
        elsif value == nil
          unless test_params.has_key?(key)
            return false
          end
        else
          if test_params[key] == value
            test_params.delete(key)
          else
            return false
          end
        end
      end

      return true, test_params
    end

    def url_parts(path)
      return path.split('/').reject(&:blank?)
    end


    # Check if a string has a binding in it
    def has_binding?(string)
      string.index('{{') && string.index('}}')
    end

end
