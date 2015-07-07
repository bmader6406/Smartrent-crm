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
    email_project = {
      :to => params[:campaign][:to],
      :from => params[:campaign][:from],
      :body_text => params[:campaign][:body_text],
      :audience_ids => [params[:campaign][:audience_id]].compact
    }

    #create root campaign
    @campaign = NewsletterCampaign.new({
      :property_id => @property.id,
      :template_id => template.id,
      :annotation => params[:campaign][:subject],
      :user_id => @property.user_id,
    })
    
    respond_to do |format|
      if @campaign.save(:validate => false)
        # create variant
        # not support ab test
        variate_campaign = @campaign.class.new({
          :property_id => @campaign.property_id, 
          :template_id => @campaign.template_id, 
          :user_id => @campaign.user_id,
          :root_id => @campaign.id
        })

        variate_campaign.save(:validate => false)

        @campaign.channel_variates.create(:variate_campaign_id => variate_campaign.id, :weight_percent => 100)

        # update subject, body
        hylet = variate_campaign.newsletter_hylet
        hylet.subject = params[:campaign][:subject]
        hylet.body_html = replace_macro(template.campaign.newsletter_hylet.body_html, email_project[:body_text])
        hylet.body_plain = "View on browser {%email_url%}"
        hylet.email_project = email_project
        hylet.save!
        
        hylet = Hylet.find(hylet.id) #must reload, otherwise audience_ids is empty
        
        # schedule the email
        if hylet.audience_ids.empty?
          @error = "No Lead Group Found! Please select a group"

        elsif published_at <= Time.now + 15.minutes
          @error = "You have to wait for 15 minutes before you can schedule a send!"

        else
          action = SendNewsletterAction.schedule(@campaign, published_at)

          # not support multi schedule
          schedules = [] #hylet.schedules
          schedules << {"timestamp" => published_at.to_i, "action_id" => action.id, "is_send" => false, "subject" => {}}
          schedules = schedules.sort{|a, b| a["timestamp"].to_i <=> b["timestamp"].to_i }

          hylet.update_attributes(:email_project => {:schedules => schedules})

          @campaign.update_attributes(:published_at => Time.at(schedules.first["timestamp"].to_i))
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
    email_project = {
      :to => params[:campaign][:to],
      :from => params[:campaign][:from],
      :body_text => params[:campaign][:body_text],
      :audience_ids => [params[:campaign][:audience_id]].compact
    }
    
    respond_to do |format|
      if @campaign.update_attributes(:annotation => params[:campaign][:subject])
        # abort and schedule on update
        # not support ab test
        hylet = @campaign.first_nlt_hylet
        hylet.subject = params[:campaign][:subject]
        hylet.body_html = replace_macro(template.campaign.newsletter_hylet.body_html, email_project[:body_text])
        hylet.email_project = email_project
        hylet.save!
        action = DelayedAction.where(:actor_id => @campaign.property_id, :subject_id => @campaign.id).order('execute_at asc').first
        
        if action && action.execute_at != published_at || !action
          
          if action
            schedules = hylet.schedules.delete_if{|s| s["action_id"].to_i == action.id}

            hylet.update_attributes(:email_project => {:schedules => schedules})

            action.destroy
            
            if schedules.empty?
              @campaign.update_attributes(:published_at => nil)
            end
          end

          # reschedule
          action = SendNewsletterAction.schedule(@campaign, published_at)
          
          # not support multi schedule
          schedules = [] #hylet.schedules
          schedules << {"timestamp" => published_at.to_i, "action_id" => action.id, "is_send" => false, "subject" => {}}
          schedules = schedules.sort{|a, b| a["timestamp"].to_i <=> b["timestamp"].to_i }

          hylet.update_attributes(:email_project => {:schedules => schedules})

          @campaign.update_attributes(:published_at => Time.at(schedules.first["timestamp"].to_i))
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
    @body_html = @campaign.first_nlt_hylet.body_html
    render :layout => false
  end
  
  def preview_template
    template = ::Template.find_by(property_id: @property.id)
    
    if template
      hylet = template.campaign.newsletter_hylet
      if params[:cid]
        @body_html = replace_macro(hylet.body_html, @property.campaigns.find(params[:cid]).first_nlt_hylet.email_project["body_text"])
      else
        @body_html = replace_macro(hylet.body_html, hylet.email_project["body_text"])
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
      
      ["id", "annotation"].each do |k|
        next if params[k].blank?
        arr << "#{k} = :#{k}"
        hash[k.to_sym] = params[k]
      end
      
      @campaigns = Campaign.for_property(@property).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("published_at asc")
      
      # eager load newsletter hylet
      root_va_ids = Campaign.where(:root_id => @campaigns.collect{|c| [c.id, c.group_id] }.flatten.compact.uniq, :parent_id => nil).collect{|c| [c.root_id, c.id] }

      # build newsletter hylet dict
      nlt_dict = {}
      
      NewsletterHylet.where(:campaign_id => root_va_ids.collect{|r| r[1] }.uniq ).all.each do |hylet|
        root_id = root_va_ids.detect{|r| r[1] == hylet.campaign_id}[0]
        nlt_dict[root_id] = hylet
      end
      
      aud_dict = {}
      audiences = Audience.where(:id => nlt_dict.values.collect{|h| h.audience_ids }.flatten.compact ).includes(:property, :campaign).all
      nlt_dict.keys.each do |k|
        hylet = nlt_dict[k]
        hylet.set_audience_name( audiences.collect{|a| a if hylet.audience_ids.include?(a.id.to_s) }.compact.collect{|a| a.name } )
      end
      
      @campaigns.each do |c|
        hylet = nlt_dict[c.id]
        c.set_newsletter_hylet(hylet) if hylet
      end
      
    end
end