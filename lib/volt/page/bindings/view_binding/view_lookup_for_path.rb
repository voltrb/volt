module Volt
  # ViewFinderForPath helps find the location of view file given
  # a template path.
  class ViewLookupForPath
    # Takes in the path of the current view file.  This allows for relative paths
    # to be run.
    #
    # @param [Page] the page object
    # @param [String] the path of the current view
    def initialize(page, binding_in_path)
      @page = page
      path_parts       = binding_in_path.split('/')
      @collection_name = path_parts[0]
      @controller_name = path_parts[1]
      @page_name       = path_parts[2]
    end

    # Returns true if there is a template at the path
    def check_for_template?(path)
      @page.templates[path]
    end

    # Takes in a lookup path and returns the full path for the matching
    # template.  Also returns the controller and action name if applicable.
    #
    # Looking up a path is fairly simple.  There are 4 parts needed to find
    # the html to be rendered.  File paths look like this:
    # app/{component}/views/{controller_name}/{view}.html
    # Within the html file may be one or more sections.
    # 1. component (app/{comp})
    # 2. controller
    # 3. view
    # 4. sections
    #
    # When searching for a file, the lookup starts at the section, and moves up.
    # when moving up, default values are provided for the section, then view/section, etc..
    # until a file is either found or the component level is reached.
    #
    # The defaults are as follows:
    # 1. component - main
    # 2. controller - main
    # 3. view - index
    # 4. section - body
    def path_for_template(lookup_path, force_section = nil)
      parts      = lookup_path.split('/')
      parts_size = parts.size

      default_parts     = %w(main main index body)

      # When forcing a sub template, we can default the sub template section
      default_parts[-1] = force_section if force_section

      (5 - parts_size).times do |path_position|
        # If they passed in a force_section, we can skip the first
        next if force_section && path_position == 0

        full_path = [@collection_name, @controller_name, @page_name, nil]

        start_at = full_path.size - parts_size - path_position

        full_path.size.times do |index|
          if index >= start_at
            if (part = parts[index - start_at])
              full_path[index] = part
            else
              full_path[index] = default_parts[index]
            end
          end
        end

        path = full_path.join('/')
        if check_for_template?(path)
          controller = nil

          if path_position >= 1
            init_method = full_path[2]
          else
            init_method = full_path[3]
          end

          # Lookup the controller
          controller = [full_path[0], full_path[1] + '_controller', init_method]

          return path, controller
        end
      end

      [nil, nil]
    end

  end
end