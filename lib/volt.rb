require 'volt/volt/environment'
require 'volt/extra_core/extra_core'
require 'volt/reactive/reactive_value'

class Volt
  def self.root
    @root ||= File.expand_path(Dir.pwd)
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
end