require 'volt/volt/environment'
require 'volt/extra_core/extra_core'
require 'volt/reactive/computation'
require 'volt/reactive/dependency'
if RUBY_PLATFORM == 'opal'
else
  require 'volt/config'
  require 'volt/data_stores/data_store'
end

class Volt
  if RUBY_PLATFORM == 'opal'
    @@in_browser = `!!document && !window.OPAL_SPEC_PHANTOM`
  else
    @@in_browser = false
  end

  def self.root
    @root ||= File.expand_path(Dir.pwd)
  end

  def self.root=(val)
    @root = val
  end

  def self.server?
    !!ENV['SERVER']
  end

  def self.client?
    !ENV['SERVER']
  end

  def self.source_maps?
    !!ENV['MAPS']
  end

  def self.env
    @env ||= Volt::Environment.new
  end

  def self.logger
    @logger ||= Logger.new
  end

  def self.logger=(val)
    @logger = val
  end

  def self.in_browser?
    @@in_browser
  end

end
