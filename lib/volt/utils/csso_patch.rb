# CSSO complains when using node as an execJS runtime, but we currently have
# to due to a bug in therubyracer (or maybe execJS?)

require 'execjs'

module Csso
  class JsLib
    def initialize
      spec = Gem::Specification.find_by_name('csso-rails')
      path = spec.gem_dir

      lib = File.read(File.expand_path(path + '/' + CSSO_JS_LIB, File.dirname(__FILE__)))
      fail 'cannot compile or what?' unless @csso = ExecJS.runtime.compile(lib)
    end

    def compress(css, structural_optimization = true)
      @csso.call('do_compression', css, !structural_optimization)
    end
  end
end
