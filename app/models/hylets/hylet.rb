class Hylet < ActiveRecord::Base
  
  belongs_to :campaign
  
  attr_accessor :curr_index, :meta
  
  def property #don't move to association
    campaign.property
  end
  
  def self.pretty_name
    self.to_s
  end
  
  def duplicate(parent = nil)
    h2 = self.dup
    h2.el_id = nil # to re-generate
      
    h2.save!
    h2
  end
  
  def label_copied
    label ? "#{label} (copied)" : "(copied at #{Time.now.strftime('%l:%M %p')})"
  end
  
end
