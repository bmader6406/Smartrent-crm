class Nimda::TemplatesController < NimdaController
  
  before_action :require_user #don't remove
  before_action :get_template, :except => [:index, :create, :import]
  before_action :set_page_title
    
  # GET /templates
  def index
    params[:group_id] = "all" if !params[:group_id]
    params[:category] = "all" if !params[:category]
    
    @templates = Template.approved.includes(:template_group)
    @templates = @templates.where("group_id = ?", params[:group_id]) if params[:group_id] != "all"
    @templates = @templates.where("category = ?", params[:category]) if params[:category] != "all"
    
    if params[:channel]
      @templates = @templates.where("channel = ?", params[:channel])
    else
      @templates = @templates.where("channel != 'email'")
    end
    
    @templates = @templates.paginate(:page => params[:page], :per_page => 50)
    
    @pending_templates = Template.pending.includes(:template_group)
    
    if params[:channel]
      @pending_templates = @pending_templates.where("channel = ?", params[:channel])
    else
      @pending_templates = @pending_templates.where("channel != 'email'")
    end
    
    @pending_templates = @pending_templates.paginate(:page => params[:p_page], :per_page => 20)
  end
  
  def create
    source_template = Template.find_all_by_channel_and_approved_and_deleted_at(params[:channel], true, nil).last

    if source_template
      parent_template = source_template.duplicate

      redirect_to(nimda_template_url(parent_template), :notice => 'Template was successfully created.')
    else
      flash[:error] = "Please create the first template."
      redirect_to params[:channel] == "email" ? nimda_templates_url(:channel => "email") : nimda_templates_url
    end
  end
  
  def duplicate
    parent_template = @template.duplicate

    redirect_to(nimda_template_url(parent_template), :notice => 'Template was successfully duplicated.')
  end
  
  def show
  end
  
  def edit
    session[:editing_campaign_id] = @template.campaign.id
    redirect_to edit_landing_campaign_url(@template.campaign, :protocol => "http")
  end
  
  def preview
    @campaign = @template.campaign
    @property = @campaign.property
    
    @preview = true
      
    render :layout => false, :partial => "shared/newsletter_preview"
  end


  # PUT /templates/1
  def update
    
    respond_to do |format|
      if @template.update_attributes(params[:template])
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
    
    redirect_to @template.landing? ? nimda_templates_url : nimda_templates_url(:channel => "email") 
  end
  
  def approve
    
    @template.approved = true
    
    if @template.save
      flash[:notice] = "Template was successfully approved"

      redirect_to @template.landing? ? nimda_templates_url : nimda_templates_url(:channel => "email", :category => @template.category)       
    else
      render :action => :show
    end
    
  end
  
  def unapprove
    
    @template.approved = false
    
    if @template.save
      flash[:notice] = "Template was successfully approved"
      redirect_to @template.landing? ? nimda_templates_url : nimda_templates_url(:channel => "email") 
    else
      render :action => :show
    end
    
  end
  
  def lead_def
    @template_options = TemplateOption.all
    @template_columns = TemplateColumn.all
    @lead_def = @template.campaign.form.lead_def rescue nil
    
    if !@lead_def
      flash[:error] = "No Leaddef Found!"
      redirect_to nimda_templates_url and return
    end
  end
  
  def import
    
    attrs = JSON.parse(params[:tpl_file].read) rescue nil
    
    #check file before import
    
    if attrs
      attrs["user_id"] = current_user.id
      attrs["property_id"] = nil
      attrs["approved"] = false
      
      begin
        @template = Template.import_from_json(attrs)

      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        
        Resque.enqueue(SystemMessageMailer, "[ImportToSystemTemplates] FAILURE", error_details)
      end
    end
    
    render :layout => false
  end
  
  protected
  
    def get_template
      @template = Template.find(params[:id])
    end
    
    def set_page_title
      if action_name == "lead_def"
        @page_title = "CRM Nimda - Lead Fields Management"
      else
        @page_title = "CRM Nimda - Template Management"
      end
    end
  
end
