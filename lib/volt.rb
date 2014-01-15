require 'volt/volt/environment'

class Volt
  def self.root
    @root ||= File.expand_path(Dir.pwd)
  end
  
  def self.server?
    !ENV['CLIENT']
  end
  
  def self.client?
    !!ENV['CLIENT']
  end
  
  def self.source_maps?
    !!ENV['MAPS']
  end
  
  def self.env
    @env ||= Volt::Environment.new
  end
end