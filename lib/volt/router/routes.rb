class Routes
  attr_reader :routes

  def initialize
    @routes = []
  end
  
  def define(&block)
    instance_eval(&block)
    
    return self
  end
  
  def get(path, options)
    if path.index('{') && path.index('}')
      sections = path.split(/(\{[^\}]+\})/)
      sections = sections.reject {|v| v == '' }
      
      sections.each do |section|
        if section[0] == '{' && section[-1] == '}'
          options[section[1..-2]] = nil
        end
      end
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
    end
    
    @routes << [path, options]
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
      params = params.attributes.dup
      path = path.call(params) if path.class == Proc
    
      options.keys.each do |key|
        params.delete(key)
      end
      
      return path, params
    end
  
    def params_match_options?(params, options)
      options.each_pair do |key, value|
        # A nil value means it can match anything, so we don't want to
        # fail on nil.        
        if value != nil && value != params.send(key)
          return false
        end
      end
    
      return true
    end
end