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
      if params[:range].blank?
        if !cookies[:report_range].blank?
          start_at, end_at = cookies[:report_range].split("_", 2)
          params[:range] = [Time.at(start_at.to_i), Time.at(end_at.to_i)]
        else
          params[:range] = [Time.zone.today - 30.days, Time.zone.today - 1.day]
        end
        
        
      elsif params[:range].kind_of?(Array)
        params[:range] = [Date.parse(params[:range].first), Date.parse(params[:range].last)]
        
      end
      
      cookies[:report_range] = {
        :value => "#{params[:range][0].to_time.to_i}_#{params[:range][1].to_time.to_i}",
        :expires => Time.now + 3.hours,
        :path => "/",
        :domain => ".#{HOST.split(':').first}"
      } 
      
      params[:range][0] = params[:range][0].end_of_day
      params[:range][1] = params[:range][1].end_of_day
      
      if params[:report_type].blank?
        params[:report_type] = "daily"
      end
      
      if params[:channel].blank?
        params[:channel] = "all"
      end

    end
    
    def set_page_title
      @page_title = "CRM - #{@campaign.annotation} - Reports"
    end
    
    def conversion(num, total)
      (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
    end

end
