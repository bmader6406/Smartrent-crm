class UnitsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_unit, :except => [:index, :new, :create, :show_by_code]
  before_action :set_page_title
  
  def index
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_units(params[:per_page])
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

  def show_by_code
    @unit = Unit.find_by_property_id_and_code(params[:property_id], params[:code])
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        if @unit
          render "show"
        else
          render :json => {}
        end
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
    @unit = @property.units.new(unit_params)
    
    respond_to do |format|
      if @unit.save
        format.json { render template: "units/show.json.rabl", status: :created }
      else
        format.json { render json: @unit.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
    respond_to do |format|
      if @unit.update_attributes(unit_params)
        format.json { head :no_content }
      else
        format.json { render json: @unit.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @unit.update_attribute(:deleted_at, Time.now)
    
    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  def residents
    @residents = @unit.residents

    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/index2.json.rabl")
      }
    end
  end
  
  private
    
    def unit_params
      params.require(:unit).permit!
    end
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      
      Time.zone = @property.setting.time_zone
    end

    def set_unit
      @unit = @property.units.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, Unit
          
        when "edit", "update", "destroy"
          authorize! :cud, @unit
          
        else
          authorize! :read, @unit
      end
    end
    
    def set_page_title
      @page_title = "CRM - #{@property.name} - Units" 
    end
    
    def filter_units(per_page = 15)
      arr = []
      hash = {}
      
      ["id", "code", "status", "resident_id", "first_name", "last_name", "email"].each do |k|
        next if params[k].blank?
        arr << "#{k} = :#{k}"
        hash[k.to_sym] = params[k]
      end
      
      @units = @property.units.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("code asc")
    end
end
