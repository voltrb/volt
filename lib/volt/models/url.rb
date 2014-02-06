# The url class handles parsing and updating the url
class URL
  include ReactiveTags
  
  # TODO: we need to make it so change events only trigger on changes
  attr_reader :scheme, :host, :port, :path, :query, :params
  attr_accessor :router
  
  def initialize(router=nil)
    @router = router
    @params = Model.new({}, persistor: Persistors::Params)
  end
  
  # Parse takes in a url and extracts each sections.
  # It also assigns and changes to the params.
  tag_method(:parse) do
    destructive!
  end
  def parse(url)
    if url[0] == '#'
      # url only updates fragment
      @fragment = url[1..-1]
    else
      # Add the host for localized names
      if url[0..3] != 'http'
        host = `document.location.host`
        url = "http://#{host}" + url
      end
      
      matcher = url.match(/^(https?)[:]\/\/([^\/]+)(.*)$/)
      @scheme = matcher[1]
      @host, @port = matcher[2].split(':')
      @port ||= 80
    
      @path = matcher[3]
      @path, @fragment = @path.split('#', 2)
      @path, @query = @path.split('?', 2)

      assign_query_hash_to_params
    end
    
    scroll
  end

  # Full url rebuilds the url from it's constituent parts
  def full_url
    if @port
      host_with_port = "#{@host}:#{@port}"
    else
      host_with_port = @host
    end
    
    path, params = @router.url_for_params(@params)

    new_url = "#{@scheme}://#{host_with_port}#{(path || @path).chomp('/')}"
    
    unless params.empty?
      new_url += '?'
      query_parts = []
      nested_params_hash(params).each_pair do |key,value|
        value = value.cur
        # remove the _ from the front
        value = `encodeURI(value)`
        query_parts << "#{key}=#{value}"
      end
      
      new_url += query_parts.join('&')
    end
    
    new_url += '#' + @fragment if @fragment
    
    return new_url
  end
  
  # Called when the state has changed and the url in the
  # browser should be updated
  # Called when an attribute changes to update the url
  def update!
    if Volt.client?
      new_url = full_url()
    
      if `(document.location.href != new_url)`
        `history.pushState(null, null, new_url)`
      end
    end
  end
  
  def scroll
    if Volt.client?
      if @fragment
        # Scroll to anchor
        %x{
          var anchor = $('a[name="' + this.fragment + '"]');
          if (anchor) {
            $(document.body).scrollTop(anchor.offset().top);
          }
        }
      else
        # Scroll to the top by default
        `$(document.body).scrollTop(0);`
      end
    end
  end
  
  private
    # Assigning the params is tricky since we don't want to trigger changed on
    # any values that have not changed.  So we first loop through all current
    # url params, removing any not present in the params, while also removing
    # them from the list of new params as added.  Then we loop through the 
    # remaining new parameters and assign them.
    def assign_query_hash_to_params
      # Get a nested hash representing the current url params.
      query_hash = self.query_hash
      
      # Get the params that are in the route
      query_hash.merge!(@router.params_for_path(@path))
      
      # Loop through the .params we already have assigned.
      assign_from_old(@params, query_hash)
      assign_new(@params, query_hash)
    end
    
    # Loop through the old params, and overwrite any existing values,
    # and delete the values that don't exist in the new params.  Also
    # remove any assigned to the new params (query_hash)
    def assign_from_old(params, new_params)
      queued_deletes = []
      
      params.cur.attributes.each_pair do |name,old_val|
        # If there is a new value, see if it has [name]
        new_val = new_params ? new_params[name] : nil
        
        if !new_val
          # Queues the delete until after we finish the each_pair loop
          queued_deletes << name
        elsif new_val.is_a?(Hash)
          assign_from_old(old_val, new_val)
        else
          # assign value
          if old_val != new_val
            params.send(:"#{name}=", new_val)
          end
          new_params.delete(name)
        end
      end
      
      queued_deletes.each {|name| params.delete(name) }
    end
    
    # Assign any new params, which weren't in the old params.
    def assign_new(params, new_params)
      new_params.each_pair do |name, value|
        if value.is_a?(Hash)
          assign_new(params.send(name), value)
        else
          # assign
          params.send(:"#{name}=", value)
        end
      end
    end
    
    def query_hash
      query_hash = {}
      if @query
        @query.split('&').reject {|v| v == '' }.each do |part|
          parts = part.split('=').reject {|v| v == '' }
      
          # Decode string
          # parts[0] = `decodeURI(parts[0])`
          parts[1] = `decodeURI(parts[1])`
        
          sections = query_key_sections(parts[0])
        
          hash_part = query_hash
          sections.each_with_index do |section,index|
            if index == sections.size-1
              # Last part, assign the value
              hash_part[section] = parts[1]
            else
              hash_part = (hash_part[section] ||= {})
            end
          end
        end
      end
      
      return query_hash
    end
    
    # Splits a key from a ?key=value&... parameter into its nested 
    # parts.  It also adds back the _'s used to access them in params.
    # Example:
    # user[name]=Ryan would parse as [:_user, :_name]
    def query_key_sections(key)
      key.split(/\[([^\]]+)\]/).reject(&:empty?).map {|v| :"_#{v}"}
    end
    
    # Generate the key for a nested param attribute
    def query_key(path)
      i = 0
      path.map do |v|
        v = v[1..-1]
        i += 1
        if i != 1
          "[#{v}]"
        else
          v
        end
      end.join('')
    end
  
    def nested_params_hash(params, path=[])
      results = {}
    
      params.each_pair do |key,value|
        if value.respond_to?(:persistor) && value.persistor && value.persistor.is_a?(Persistors::Params)
          # TODO: Should be a param
          results.merge!(nested_params_hash(value, path + [key]))
        else
          results[query_key(path + [key])] = value
        end
      end
    
      return results
    end
  
end