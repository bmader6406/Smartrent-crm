class VariationMetric < ActiveRecord::Base

  belongs_to :campaign
  
  validates :campaign_id, :presence => true
  
  default_scope { order('created_at DESC, type') }
  
  before_validation :set_property_id
  
  def formatted_text(campaign = nil)
    case self['type']
      when "AppDataVariationMetric"
        !self["text"].blank? ? self["text"] : "Viral"
      when "AppDataAVariationMetric"
        !self["text"].blank? ? self["text"] : "other"
      when "AppDataBVariationMetric"
        !self["text"].blank? ? self["text"] : "other"
      when "AppDataCVariationMetric"
        !self["text"].blank? ? self["text"] : "other"
      when "AppDataDVariationMetric"
        !self["text"].blank? ? self["text"] : "other"
      when "AppDataEVariationMetric"
        !self["text"].blank? ? self["text"] : "other"
      when "ForcedLikeVariationMetric"
        "YES"
      when "NonForcedLikeVariationMetric"
        "NO"
      else
        self['text']
    end
  end  
  
  def text
    self["text"]
  end
  
  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(1)
  end
  
  private
  
    def set_property_id
      self.property_id = campaign.property_id if !self.property_id
    end
  
end
