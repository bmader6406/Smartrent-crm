class TemplateCampaign < Campaign
  
  has_one :template, :foreign_key => :campaign_id
    
end
