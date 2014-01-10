# Class to describe the interface for sections
class BaseSection
  def remove
    raise "not implemented"
  end

  def remove_anchors
    raise "not implemented"
  end
  
  def insert_anchor_before_end
    raise "not implemented"
  end
end