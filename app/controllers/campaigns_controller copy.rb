class CampaignsController < ApplicationController

  rescue_from Paypal::Exception::APIError, :with => :paypal_api_error
  
  include UserActivityHelper::Controller
  
  before_action :require_user, :except => [:public_preview, :hylet_detail]
  before_action :get_campaign, :except => [:index, :new, :create, :public_preview, :hylet_detail]
  before_action :eliminate_campaign_params, :only => [:update, :update ]
  before_action :set_page_title
  
  helper_method :view_context
  
  @@per_page = 20
  
  def index
    redirect_to pages_url and return
  end
  
  def update
    @campaign.update_attributes(params[:campaign])
  end
  
  def preview
    respond_to do |format|
      format.js { 
        render :action => "update.js.erb" 
      }
      
      format.html {
        if @campaign.newsletter_hylet
          render :layout => false, :partial => "shared/newsletter_preview"
        end
      } 
    end
  end
  
  protected  
    
    def get_campaign
      @campaign = current_user.admin_campaign(params[:id])
      @root_campaign = @campaign.to_root
  
      @property = @campaign.property
      
      Time.zone = @property.setting.time_zone
    end
    
    def eliminate_campaign_params
      campaign = params[:campaign]
      
      if campaign
        campaign[:custom_css] = eliminate_css(campaign[:custom_css]) if campaign[:custom_css]
      end
    end
    
    def eliminate_css(css)
      css.gsub(/#free-wrap/, '#hyly-id')
    end
    
    def set_page_title
      if @campaign
        if @campaign.kind_of?(TemplateCampaign)
          @page_title = "CRM - #{@campaign.template.name}"
          
        else
          if action_name == "dashboard"
            @page_title = "CRM - #{@property.name} - #{@campaign.annotation(true)} - Dashboard"
            
          elsif action_name == "sequence"
            @page_title = "CRM - #{@property.name} - #{@campaign.annotation(true)} - Sequence"
            
          else
            @page_title = "CRM - #{@property.name} - #{@campaign.annotation(true)} - Editor"
          end
        end
        
      else
        @page_title = "CRM - Campaigns"
      end
    end

end
