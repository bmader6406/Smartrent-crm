class VariationMetric < ActiveRecord::Base

  belongs_to :campaign
  
  validates :campaign_id, :presence => true
  
  default_scope { ordre('created_at DESC, type') }
  
  before_validation :set_property_id
  
  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(1)
  end
  
  private
  
    def set_property_id
      self.property_id = campaign.property_id if !self.property_id
    end
  
end
