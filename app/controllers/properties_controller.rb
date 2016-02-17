class PropertiesController < ApplicationController
  before_filter :require_user
  before_action :set_property, :except => [:index, :new, :create, :info]
  before_action :set_page_title
  
  def index
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_properties(params[:per_page])
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
  
  def info
    @property = current_user.managed_properties.find(params[:id])
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "properties/show.json.rabl")
      }
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
    @property = Property.new(property_params)
    @property.user_id = current_user.id
    
    respond_to do |format|
      if @property.save
        format.json { render template: "properties/show.json.rabl", status: :created }
      else
        format.json { render json: @property.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
    respond_to do |format|
      if !["xml_feed", "csv_feed"].include?(@property.updated_by)
        if @property.update_attributes(property_params)
          format.json { head :no_content }
        else
          format.json { render json: @property.errors.full_messages, status: :unprocessable_entity }
        end
      else
        @property.errors.add(:this, "property can't be updated")
        format.json { render json: @property.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @property.update_attribute(:deleted_at, Time.now)
    
    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  private
    def property_params
      params.require(:property).permit!
    end
    
    def set_property
      @property = Property.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, ::Property
          
        when "edit", "update", "destroy"
          authorize! :cud, @property
          
        else
          authorize! :read, @property
      end
    end
    
    def set_page_title
      @page_title = "CRM - Properties" 
    end
    
    def filter_properties(per_page = 15)
      arr = []
      hash = {}
      
      ["name", "city", "state", "zip", "property_number", "l2l_property_id", "yardi_property_id"].each do |k|
        next if params[k].blank?
        
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      if params[:property_type] == "crm" || !params[:property_type]
        arr << "is_crm = 1"
      elsif params[:property_type] == "smartrent"
        arr << "is_smartrent = 1"
      end
      
      @properties = Property.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
    end
end
