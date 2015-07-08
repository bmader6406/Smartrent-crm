class CampaignsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_campaign, :except => [:index, :new, :create, :preview_template]
  before_action :set_page_title
  
  def index
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_campaigns(params[:per_page])
      }
    end
  end

  def show
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {}
    end
  end
  
  def new
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {}
    end
  end
  
  def edit
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {}
    end
  end
  
  def create
    template = ::Template.find_by(property_id: @property.id)
    published_at = DateTime.strptime(params[:published_at], '%Y-%b-%d %l:%M %p %z')

    #create root campaign
    @campaign = NewsletterCampaign.new({
      :property_id => @property.id,
      :template_id => template.id,
      :user_id => @property.user_id,
      :from => params[:campaign][:from],
      :audience_ids => [params[:campaign][:audience_id]].compact,
      :subject => params[:campaign][:subject],
      :body_text => params[:campaign][:body_text],
      :body_html => replace_macro(template.campaign.body_html, params[:campaign][:body_text]),
      :body_plain => "View on browser {%email_url%}"
    })
    
    respond_to do |format|
      if @campaign.save(:validate => false)
        # schedule the email
        if @campaign.audience_ids.empty?
          @error = "No Lead Group Found! Please select a group"

        elsif published_at <= Time.now + 15.minutes
          @error = "You have to wait for 15 minutes before you can schedule a send!"

        else
          action = SendNewsletterAction.schedule(@campaign, published_at)

          @campaign.update_attributes(:published_at => published_at)
        end
        
        if @error
          format.json { render json: [@error], status: :unprocessable_entity }
          
        else  
          format.json { render template: "campaigns/show.json.rabl", status: :created }
          
        end
        
      else
        format.json { render json: @campaign.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
    template = ::Template.find_by(property_id: @property.id)
    published_at = DateTime.strptime(params[:published_at], '%Y-%b-%d %l:%M %p %z')

    
    respond_to do |format|
      if @campaign.update_attributes({
          :from => params[:campaign][:from],
          :audience_ids => [params[:campaign][:audience_id]].compact,
          :subject => params[:campaign][:subject],
          :body_text => params[:campaign][:body_text],
          :body_html => replace_macro(template.campaign.body_html, params[:campaign][:body_text])
        })
        
        # abort and schedule on update
        action = DelayedAction.where(:actor_id => @campaign.property_id, :subject_id => @campaign.id).order('execute_at asc').first
        
        if action && action.execute_at != published_at || !action
          
          action.destroy if action

          # reschedule
          action = SendNewsletterAction.schedule(@campaign, published_at)
          
          @campaign.update_attributes(:published_at => published_at)
        end

        format.json { head :no_content }
        
      else
        format.json { render json: @campaign.errors.full_messages, status: :unprocessable_entity }
        
      end
    end
  end
  
  def destroy
    @campaign.update_attribute(:deleted_at, Time.now)
    DelayedAction.where(:actor_id => @campaign.property_id, :subject_id => @campaign.id).delete_all
    
    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  def preview
    @body_html = @campaign.body_html
    render :layout => false
  end
  
  def preview_template
    template = ::Template.find_by(property_id: @property.id)
    
    if template
      if params[:cid]
        @body_html = replace_macro(template.campaign.body_html, @property.campaigns.find(params[:cid]).body_text)
      else
        @body_html = replace_macro(template.campaign.body_html, template.campaign.body_text)
      end
      
    else
      @body_html = "No Template Found"
    end
    
    render :layout => false, :file => "campaigns/preview"
  end

  
  private
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      
      Time.zone = @property.setting.time_zone
    end

    def set_campaign
      @campaign = @property.campaigns.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, Campaign
          
        when "edit", "update", "destroy"
          authorize! :cud, @campaign
          
        else
          authorize! :read, @campaign
      end
    end
    
    def replace_macro(body_html, body_text)        
      if action_name == "preview_template"
        body_html.gsub!("{%body_text%}", "<div id='hyly-body-text'>#{ body_text }</div>")
      else
        body_html.gsub!("{%body_text%}", body_text)
      end
      
      body_html.gsub!("{%reply_callout%}", "")
      body_html.gsub!("{%view_unsubscribe_links%}", '
        <p class="MsoNormal" align="center" style="text-align:center; 
          margin:5px; padding:5px;font-size:8.5pt;font-family:Arial,sans-serif;color:#808080;text-decoration:none">
            <a href="{%email_url%}" target="_blank" style="font-size:8.5pt;font-family:Arial,sans-serif;color:#808080;text-decoration:none">
              View in Browser
            </a> | 
            <a href="{%unsubscribe_url%}" target="_blank" style="font-size:8.5pt;font-family:Arial,sans-serif;color:#808080;text-decoration:none">
              Unsubscribe
            </a>
        </p>'
      )
      body_html
    end
    
    def set_page_title
      @page_title = "CRM - #{@property.name} - Campaigns" 
    end
    
    def filter_campaigns(per_page = 15)
      arr = []
      hash = {}
      
      ["id", "subject"].each do |k|
        next if params[k].blank?
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @campaigns = Campaign.for_property(@property).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("published_at asc")
      
      audiences = Audience.includes(:property, :campaign).all
      
      @campaigns.each do |c|
        c.set_audience_name( audiences.collect{|a| a if c.audience_ids.include?(a.id.to_s) }.compact.collect{|a| a.name } )
      end
    end
end