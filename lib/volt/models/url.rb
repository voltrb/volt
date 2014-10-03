# The url class handles parsing and updating the url
require 'volt/reactive/reactive_accessors'

class URL
  include ReactiveAccessors

  # TODO: we need to make it so change events only trigger on changes
  reactive_accessor :scheme, :host, :port, :path, :query, :params, :fragment
  attr_accessor :router

  def initialize(router=nil)
    @router = router
    @params = Model.new({}, persistor: Persistors::Params)
  end

  # Parse takes in a url and extracts each sections.
  # It also assigns and changes to the params.
  def parse(url)
    if url[0] == '#'
      # url only updates fragment
      self.fragment = url[1..-1]
      update!
    else
      host = `document.location.host`
      protocol = `document.location.protocol`

      if url !~ /[:]\/\//
        # Add the host for local urls
        url = protocol + "//#{host}" + url
      else
        # Make sure its on the same protocol and host, otherwise its external.
        if url !~ /#{protocol}\/\/#{host}/
          # Different host, don't process
          return false
        end
      end

      matcher = url.match(/^(#{protocol[0..-2]})[:]\/\/([^\/]+)(.*)$/)
      self.scheme = matcher[1]
      host, port = matcher[2].split(':')
      port ||= 80

      self.host = host
      self.port = port

      path = matcher[3]
      path, fragment = path.split('#', 2)
      path, query = path.split('?', 2)

      self.path = path
      self.fragment = fragment
      self.query = query

      assign_query_hash_to_params
    end

    scroll

    return true
  end

  # Full url rebuilds the url from it's constituent parts
  def full_url
    if port
      host_with_port = "#{host}:#{port}"
    else
      host_with_port = host
    end

    path, params = @router.params_to_url(@params.to_h)

    new_url = "#{scheme}://#{host_with_port}#{(path || self.path).chomp('/')}"

    unless params.empty?
      new_url += '?'
      query_parts = []
      nested_params_hash(params).each_pair do |key,value|
        # remove the _ from the front
        value = `encodeURI(value)`
        query_parts << "#{key}=#{value}"
      end

      new_url += query_parts.join('&')
    end

    frag = self.fragment
    new_url += '#' + frag if frag.present?

    return new_url
  end

  # Called when the state has changed and the url in the
  # browser should be updated
  # Called when an attribute changes to update the url
  def update!
    if Volt.client?
      new_url = full_url()

      # Push the new url if pushState is supported
      # TODO: add fragment fallback
      %x{
        if (document.location.href != new_url && history && history.pushState) {
          history.pushState(null, null, new_url);
        }
      }
    end
  end

  def scroll
    if Volt.client?
      frag = self.fragment
      if frag
        # Scroll to anchor via http://www.w3.org/html/wg/drafts/html/master/browsers.html#scroll-to-fragid
        %x{
          var anchor = $('#' + frag);
          if (anchor.length == 0) {
            anchor = $('*[name="' + frag + '"]:first');
          }
          if (anchor && anchor.length > 0) {
            console.log('scroll to: ', anchor.offset().top);
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
      new_params = @router.url_to_params(path)

      if new_params == false
        raise "no routes match path: #{path}"
      end

      query_hash.merge!(new_params)

      # Loop through the .params we already have assigned.
      assign_from_old(@params, query_hash)
      assign_new(@params, query_hash)
    end

    # Loop through the old params, and overwrite any existing values,
    # and delete the values that don't exist in the new params.  Also
    # remove any assigned to the new params (query_hash)
    def assign_from_old(params, new_params)
      queued_deletes = []

      params.attributes.each_pair do |name,old_val|
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
      qury = self.query
      if qury
        qury.split('&').reject {|v| v == '' }.each do |part|
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
