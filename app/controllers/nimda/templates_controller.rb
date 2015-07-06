class Nimda::TemplatesController < NimdaController
  before_action :require_user #don't remove
  before_action :get_template, :except => [:index, :create, :import]
  before_action :set_page_title
    
  # GET /templates
  def index
    params[:category] = "all" if !params[:category]
    
    @templates = Template.approved
    @templates = @templates.where("category = ?", params[:category]) if params[:category] != "all"
    
    @templates = @templates.paginate(:page => params[:page], :per_page => 50)
    
    @pending_templates = Template.pending
    @pending_templates = @pending_templates.paginate(:page => params[:p_page], :per_page => 20)
  end
  
  def create
    template_campaign = TemplateCampaign.create(:annotation => "Nimda Template")
    template_campaign.hylets.create(:type => "NewsletterHylet", :title2 => "raw_html")

    template = Template.new({
      :user_id => current_user.id,
      :campaign => template_campaign,
      :name => template_campaign.annotation,
      :category => "email_newsletter"
    })

    if template.save
      redirect_to(nimda_template_url(template), :notice => 'Template was successfully created.')
    else
      flash[:error] = "There was an error, please try again"
      redirect_to nimda_templates_url
    end
  end
  
  def duplicate
    parent_template = @template.duplicate

    redirect_to(nimda_template_url(parent_template), :notice => 'Template was successfully duplicated.')
  end
  
  def show
  end
  
  def preview
    @campaign = @template.campaign
    @property = @campaign.property
    
    render :layout => false
  end


  # PUT /templates/1
  def update
    
    respond_to do |format|
      if @template.update_attributes(template_params)
        @template.campaign.newsletter_hylet.update_attributes(:body_html => params[:body_html])
        
        format.html { redirect_to(nimda_template_url(@template), :notice => 'Template was successfully updated.') }
      else
        show
        format.html { render :action => "show" }
      end
    end
  end

  # DELETE /templates/1
  def destroy
    
    @template.update_attribute(:deleted_at, Time.now)
    
    flash[:notice] = "Template was successfully archived"
    
    redirect_to nimda_templates_url
  end
  
  def approve
    
    @template.approved = true
    
    if @template.save
      flash[:notice] = "Template was successfully approved"

      redirect_to nimda_templates_url(:category => @template.category)       
    else
      render :action => :show
    end
    
  end
  
  def unapprove
    
    @template.approved = false
    
    if @template.save
      flash[:notice] = "Template was successfully approved"
      redirect_to nimda_templates_url
    else
      render :action => :show
    end
    
  end
  
  protected
    
    def template_params
      params.require(:template).permit!
    end
    
    def get_template
      @template = Template.find(params[:id])
    end
    
    def set_page_title
      @page_title = "CRM Nimda - Template Management"
    end
  
end
