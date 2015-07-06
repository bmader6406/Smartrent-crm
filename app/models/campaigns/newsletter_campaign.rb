class NewsletterCampaign < Campaign
  
  after_create :create_hylets, :if => lambda { |c| !c.root? && !c.duplicating }

  # also update NewsletterRescheduleCampaign when changing the above callback
end