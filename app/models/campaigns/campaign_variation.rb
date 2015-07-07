class CampaignVariation < ActiveRecord::Base

  belongs_to :campaign
  belongs_to :variate_campaign, :class_name => "Campaign", :foreign_key => :variate_campaign_id
      
  validates :weight_percent, :numericality => {:greater_than => -1, :less_than => 101}
  
  default_scope { order('campaign_variations.created_at ASC')} #important: don't change the ASC order
  
  after_create :update_all_variates
  after_destroy :update_all_variates
  after_destroy :correct_metrics

  attr_accessor :name, :index
  
  private
    
    #allow only 3 variates for now
    
    def update_all_variates
      if campaign_id != variate_campaign_id
        
        variates = self.variate_campaign.channel_variates
        percentages = [100]
        
        case variates.length
          when 1
            percentages = [100]
          when 2
            percentages = [50, 50]
          when 3
            percentages = [34, 33, 33]
          when 4
            percentages = [25, 25, 25, 25]
          when 5
            percentages = [20, 20, 20, 20, 20]
        end
        
        variates.each_with_index do |v, index|
          v.update_attribute(:weight_percent, percentages[index])
        end
        
      end
    end
    
end