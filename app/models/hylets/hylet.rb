class Hylet < ActiveRecord::Base
  
  include MultiTenant::RandomPrimaryKeyHelper
  
  belongs_to :campaign
  
  before_create :set_el_id
  
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
  
  private
  
    def set_el_id #use to display the rows, columns, elements
      self.el_id = id if !el_id
    end
    
end
