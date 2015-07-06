class Nimda::NewsletterHyletsController < NimdaController
  before_filter :get_custom_hylet, :except => [:index, :new, :create, :campaigns]
  before_filter :set_page_title
  
  def index
    @custom_hylets = custom_hylet_clzz.includes(:children)
    
    if !params[:search].blank?
      @custom_hylets = @custom_hylets.where("label LIKE ?", "%#{params[:search]}%") 
    end
    
    @custom_hylets = @custom_hylets.paginate(:page => params[:page], :per_page => 20, :order => "label asc")
  end
  
  def campaigns
    params[:by] = "campaign_name" if params[:by].blank?
    
    @campaigns = Campaign.joins(:hylets).where("campaigns.page_persona_id IS NOT NULL AND hylets.type IN ('NewsletterHylet')").includes([:hylets, :page_persona])
    
    if !params[:search].blank?
      params[:search].strip!
      
      if params[:by] == "campaign_name"
        @campaigns = @campaigns.where("campaigns.type = 'NewsletterCampaign' AND campaigns.annotation LIKE ?", "%#{params[:search]}%")
        
      elsif params[:by] == "campaign_id"
        @campaigns = @campaigns.where("campaigns.id = ?", params[:search])
        
      elsif params[:by] == "template_name"
        campaign_ids = []
        Template.where("category = 'email_newsletter' AND name LIKE ?", "%#{params[:search]}%").each do |t|
          campaign_ids << t.campaign_id
        end
        @campaigns = @campaigns.where("campaigns.id IN (?)", campaign_ids)

      elsif params[:by] == "hylet_name"
        @campaigns = @campaigns.where("hylets.label LIKE ?", "%#{params[:search]}%")
          
      else
        ids = Tenant.where("persona_id IS NOT NULL AND name LIKE ?", "%#{params[:search]}%").collect{|t| t.persona_id }
        @campaigns = @campaigns.where(:page_persona_id => ids)
      end
    end
    
    @campaigns = @campaigns.paginate(:page => params[:page], :per_page => 20, :order => "annotation asc")
  end

  def show
    render :layout => false
  end
  
  def new
    @custom_hylet = custom_hylet_clzz.create(:label => "Untitled")

    redirect_to edit_nimda_custom_hylet_url(@custom_hylet)
  end

  def update
    @custom_hylet.update_attributes(params[:custom_hylet])
    
    if @custom_hylet.campaign
      @custom_hylet.campaign.newsletter_hylet.update_attributes(:style1 => params[:css])
    end
    
    respond_to do |format|
      format.html {
        flash[:notice] = 'Custom Hylet was successfully updated.'
        redirect_to :action => :edit
      }
      format.json {
        if @custom_hylet.errors.empty?
          render :json => {:success => true}
        else
          render :json => {:success => false, :error => @custom_hylet.errors.full_messages.join(', ') }
        end
      }
    end  
  end

  def destroy
    @custom_hylet.destroy
    
    flash[:notice] = 'Custom Hylets was successfully deleted.'
    
    redirect_to nimda_custom_hylets_url(:type => params[:type])
  end
  
  def duplicate
    hylet = @custom_hylet.dup
    hylet.label = "#{hylet.label} (copied)"
    
    if hylet.save
      flash[:notice] = 'Custom Hylets was successfully created.'
    else
      flash[:error] = "There was an error, please try again! (#{hylet.errors.full_messages.join(', ')})"
    end
    
    redirect_to nimda_custom_hylets_url(:type => params[:type])
  end
  
  def assign
    page_persona = Persona.find_by_id(params[:pid])
    hylet = page_persona ? @custom_hylet.children.find_or_initialize_by_page_persona_id(page_persona.id) : nil
    
    if hylet && hylet.save
      render :json => {:success => true, :page_name => page_persona.name }
      
    else
      render :json => {:success => false}
      
    end
  end
  
  def unassign
    hylet = @custom_hylet.children.where(:page_persona_id => params[:pid]).first
    
    if hylet && hylet.destroy
      flash[:notice] = "Custom Hylet was successfully unassigned"
      redirect_to params[:return_to]
      
    else
      flash[:error] = "There was an error, please try again! (#{hylet.errors.full_messages.join(', ')})"
      redirect_to params[:return_to]
      
    end
  end
  
  def assigned_pages
    @pages = @custom_hylet.children.includes(:page_persona2 => :tenant).collect{|c| c.page_persona2 }
  end
  
  def preview_editor
    @custom_hylet.text1 = params[:text1] #don't save
  end
  
  def custom_hylet_clzz
    NewsletterHylet.nimda #disable custom hylet for landing page
  end
  
  protected
    
    def get_custom_hylet
      # both nimda and campaigns
      @custom_hylet = Hylet.find(params[:id])
    end
    
    def set_page_title
      @page_title = "Hy.ly Nimda - Custom Hylets"
    end
    
end
