require 'volt'

class Routes
  attr_reader :routes, :path_matchers

  def initialize
    @routes = []
    
    if Volt.server?
      @path_matchers = []
    end
  end
  
  def define(&block)
    instance_eval(&block)
    
    return self
  end
  
  def get(path, options={})
    if path.index('{') && path.index('}')
      # The path contains bindings.
      path = build_path_matcher(path, options)
    else
      add_path_matcher([path]) if Volt.server?
    end
    
    @routes << [path, options]
  end
  
  # Takes the path and splits it up into sections around any
  # bindings in the path.  Those are then used to create a proc
  # that will return the path with the current params in it.
  # If it matches it will be used.
  def build_path_matcher(path, options)
    sections = path.split(/(\{[^\}]+\})/)
    sections = sections.reject {|v| v == '' }
    
    sections.each do |section|
      if section[0] == '{' && section[-1] == '}'
        options[section[1..-2]] = nil
      end
    end
    
    add_path_matcher(sections) if Volt.server?
    
    path = Proc.new do |params|
      # Create a path using the params in the path
      sections.map do |section|
        if section[0] == '{' && section[-1] == '}'
          params[section[1..-2]]
        else
          section
        end
      end.join('')
    end
    
    return path
  end

  # TODO: This is slow, optimize with a DFA or NFA
  def add_path_matcher(sections)
    match_path = ''
    sections.each do |section|
      if section[0] == '{' && section[-1] == '}'
        match_path = match_path + "[^\/]+"
      else
        match_path = match_path + section
      end
    end
    
    @path_matchers << (/^#{match_path}$/)
  end
  
  # Takes in params and generates a path and the remaining params
  # that should be shown in the url.
  def url_for_params(params)    
    routes.each do |route|
      if params_match_options?(params, route[1])
        return path_and_params(params, route[0], route[1])
      end
    end
    
    return '/', params
  end

  # Takes in a path and returns the matching params.
  def params_for_path(path)
    routes.each do |route|
      if route[0] == path
        # Found the matching route
        return route[1]
      end
    end
    
    return {}
  end
  
  private
    def path_and_params(params, path, options)
      puts "---#{params.inspect} - #{path.inspect} -- #{options.inspect}"
      params = params.attributes.dup
      path = path.call(params) if path.class == Proc
    
      options.keys.each do |key|
        params.delete(key)
      end
      
      return path, params
    end
  
    # Match one route against the current params.
    def params_match_options?(params, options)
      options.each_pair do |key, value|
        # If the value is a hash, we have a nested route.  Get the
        # matching section in the parameter and loop down to check
        # the values down.
        if value.is_a?(Hash)
          sub_params = params.send(key)

          if sub_params
            return params_match_options?(sub_params, value)
          else
            return false
          end
        elsif value != nil && value != params.send(key)
          # A nil value means it can match anything, so we don't want to
          # fail on nil.
          return false
        end
      end
    
      return true
    end
end