class RoommatesController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_roommate, :except => [:index, :new, :create]
  
  def index      
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        @roommates = []
        
        Resident.ordered("first_name asc").where("properties" => {
          "$elemMatch" => { "property_id" => @property.id.to_s, "unit_id" => params[:unit_id], "roommate" => true}
        }).each do |r|
          r.curr_property_id = @property.id
          @roommates << r
        end
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
    #consolidate roommate by email
    @roommate = Resident.with(:consistency => :strong).where(:email_lc => roommate_params[:email].downcase ).unify_ordered.first
    @roommate = Resident.new if !@roommate
    
    @roommate.curr_property_id = @property.id
    
    Resident::CORE_FIELDS.each do |f|
      if !roommate_params[f].blank?
        if [:full_name].include?(f)
          @roommate.full_name = roommate_params[f]
        else
          @roommate[f] = roommate_params[f]
        end
        
        if [:birthday].include?(f)
          @roommate[f] = Date.strptime(roommate_params[f], '%m/%d/%Y') rescue nil
        end
      end
    end
    
    #params[:property_id] come from property dropdown of org-group level form
    property_attrs = {
      :property_id => params[:property_id] || @property.to_property_id,
      :unit_id => params[:unit_id],
      :roommate => true
    }
    
    Resident::PROPERTY_FIELDS.each do |f|
      property_attrs[f] = roommate_params[f] if !roommate_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
        property_attrs[f] = Date.strptime(property_attrs[f], '%m/%d/%Y') rescue nil
      end
    end

    respond_to do |format|
      if @roommate.save
        #create submit
        @roommate.sources.create(property_attrs) if property_attrs[:property_id]
        format.json { render template: "roommates/show.json.rabl", status: :created }
      else
        format.json { render json: @roommate.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    Resident::CORE_FIELDS.each do |f|
      if !roommate_params[f].blank?
        if [:full_name].include?(f)
          @roommate.full_name = roommate_params[f]
        else
          @roommate[f] = roommate_params[f]
        end
        
        if [:birthday].include?(f)
          @roommate[f] = Date.strptime(roommate_params[f], '%m/%d/%Y') rescue nil
          roommate_params[f] = @roommate[f] # must use string
        end
      end
    end
    
    #params[:property_id] come from property dropdown of org-group level form
    property_attrs = {
      :property_id => params[:property_id] || @property.to_property_id,
      :unit_id => params[:unit_id],
      :roommate => true
    }
    
    Resident::PROPERTY_FIELDS.each do |f|
      property_attrs[f] = roommate_params[f] if !roommate_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
        property_attrs[f] = Date.strptime(property_attrs[f], '%m/%d/%Y') rescue nil
      end
      
      if [:lessee, :arc_check].include?(f) && property_attrs[f]
        property_attrs[f] = property_attrs[f].to_s == "0" ? false : true
      end
    end
    
    respond_to do |format|
      if @roommate.update_attributes(roommate_params)
        @roommate.sources.create(property_attrs) if property_attrs[:property_id]
        format.json { render template: "roommates/show.json.rabl" }
      else
        format.json { render json: @roommate.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @property
      @roommate.properties.detect{|p| p.property_id.to_i == @property.id }.destroy
    else
      @roommate.update_attribute(:deleted_at, Time.now)
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end


  private
    def roommate_params
      params.require(:roommate).permit!
    end
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      Time.zone = @property.setting.time_zone
    end
    
    def set_roommate
      @roommate = Resident.find(params[:id])
      @roommate.curr_property_id = @property.id
      
      case action_name
        when "create"
          authorize! :cud, Resident
          
        when "edit", "update", "destroy"
          authorize! :cud, @roommate
          
        else
          authorize! :read, @roommate
      end
    end

end