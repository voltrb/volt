# CSSO complains when using node as an execJS runtime, but we currently have
# to due to a bug in therubyracer (or maybe execJS?)

require 'execjs'

module Csso
  class JsLib

    def initialize
      spec = Gem::Specification.find_by_name("csso-rails")
      path = spec.gem_dir

      lib = File.read(File.expand_path(path + "/" + CSSO_JS_LIB, File.dirname(__FILE__)))
      unless @csso = ExecJS.runtime.compile(lib)
        raise 'cannot compile or what?'
      end
    end

    def compress css, structural_optimization=true
      @csso.call("do_compression", css, !structural_optimization)
    end
  end


  # https://github.com/Vasfed/csso-rails/pull/23/files
  def self.install(sprockets)
    if sprockets.respond_to? :register_compressor
      compressor = Compressor.new
      sprockets.register_compressor('text/css', :csso, proc { |context, css|
        compressor.compress(css)
      })
      sprockets.css_compressor = :csso
    else
      Sprockets::Compressors.register_css_compressor(:csso, 'Csso::Compressor', default: true)
    end
  end

end