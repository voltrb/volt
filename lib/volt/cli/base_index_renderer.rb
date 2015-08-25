# Render the config/base/index.html when precompiling.  Here we only render
# one js and one css file.

module Volt
  class BaseIndexRenderer
    def initialize(manifest)
      @manifest = manifest
    end

    def html
      index_path = File.expand_path(File.join(Volt.root, 'config/base/index.html'))
      html       = File.read(index_path)

      ERB.new(html, nil, '-').result(binding)
    end

    # When writing the index, we render the
    def javascript_tags
      "<script async src=\"/assets/#{@manifest['assets']['main/app.js']}\"></script>"
    end

    def css_tags
      "<link href=\"/assets/#{@manifest['assets']['main/app.css']}\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />"
    end
  end
end