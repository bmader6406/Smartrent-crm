class CampaignReportsController < ApplicationController
  
  before_action :require_user
  before_action :set_campaign
  before_action :set_filter_params
  before_action :set_page_title
  
  @@per_page = 20
  
  def index
  end

  protected
  
    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
      @property = @campaign.property
      
      Time.zone = @property.setting.time_zone
      
      case action_name
        when "create"
          authorize! :cud, Campaign
          
        when "edit", "update", "destroy"
          authorize! :cud, @campaign
          
        else
          authorize! :read, @campaign
      end
    end
    
    def set_filter_params
      # placeholder
    end
    
    def set_page_title
      @page_title = "CRM - #{@campaign.subject} - Reports"
    end
    
    def conversion(num, total)
      (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
    end

end
