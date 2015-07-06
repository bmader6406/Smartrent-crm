class CampaignLibrary
  
  def self.create_default_hylets(campaign)
    hylets = []
    portfolios = []
    faqs = []
    
    template = Template.find_by_id(campaign.template_id)
  
    if template && template.campaign
      template.campaign.hylets.each do |h|
    
        h2 = campaign.new_record? ? h : h.dup
    
        h2.campaign_id = campaign.id
        
        hylets << h2
      end
    end

    #save or temporary add hylet to the preview
    hylets.each do |hylet| 
      if campaign.new_record?
        campaign.hylets << hylet
        #Do not save temporary hylets
    
      else #call from model
        if hylet.kind_of?(NewsletterHylet)
          hylet.email_project = {:audience_ids => [], :schedules => []}
        end
        
        hylet.save(:validate => false)
      end
    end
    
    return campaign
    
  end    
end
