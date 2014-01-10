class Volt
  def self.root
    @root ||= File.expand_path(Dir.pwd)
    
    # File.expand_path(File.join(File.dirname(__FILE__), "../"))
  end
  
  def self.server?
    !ENV['CLIENT']
  end
  
  def self.client?
    !!ENV['CLIENT']
  end
end