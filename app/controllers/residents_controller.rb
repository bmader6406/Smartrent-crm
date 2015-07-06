class ResidentsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_resident, :except => [:index, :new, :create, :search]
  before_action :set_page_title
  
  def index      
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_residents(params[:per_page])
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
    #consolidate resident by email
    @resident = Resident.with(:consistency => :strong).where(:email_lc => resident_params[:email].downcase ).unify_ordered.first
    @resident = Resident.new if !@resident

    Resident::CORE_FIELDS.each do |f|
      if !resident_params[f].blank?
        if [:full_name].include?(f)
          @resident.full_name = resident_params[f]
        else
          @resident[f] = resident_params[f]
        end
        
        if [:birthday].include?(f)
          @resident[f] = Date.strptime(resident_params[f], '%m/%d/%Y') rescue nil
        end
      end
    end
    
    #params[:property_id] come from property dropdown of org-group level form
    property_attrs = {
      :property_id => params[:property_id]
    }
    
    Resident::PROPERTY_FIELDS.each do |f|
      property_attrs[f] = resident_params[f] if !resident_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
        property_attrs[f] = Date.strptime(property_attrs[f], '%m/%d/%Y') rescue nil
      end
    end

    respond_to do |format|
      if @resident.save
        #create submit
        @resident.sources.create(property_attrs) if property_attrs[:property_id]
        format.json { render template: "residents/show.json.rabl", status: :created }
      else
        format.json { render json: @resident.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    Resident::CORE_FIELDS.each do |f|
      if !resident_params[f].blank?
        if [:full_name].include?(f)
          @resident.full_name = resident_params[f]
        else
          @resident[f] = resident_params[f]
        end
        
        if [:birthday].include?(f)
          @resident[f] = Date.strptime(resident_params[f], '%m/%d/%Y') rescue nil
          resident_params[f] = @resident[f] # must use string
        end
      end
    end
    
    #params[:property_id] come from property dropdown of org-group level form
    property_attrs = {
      :property_id => params[:property_id]
    }
    
    Resident::PROPERTY_FIELDS.each do |f|
      property_attrs[f] = resident_params[f] if !resident_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && property_attrs[f]
        property_attrs[f] = Date.strptime(property_attrs[f], '%m/%d/%Y') rescue nil
      end
    end
    pp resident_params
    respond_to do |format|
      if @resident.update_attributes(resident_params)
        @resident.sources.create(property_attrs)  if property_attrs[:property_id]
        format.json { render template: "residents/show.json.rabl" }
      else
        format.json { render json: @resident.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @property
      @resident.properties.detect{|p| p.property_id.to_i == @property.id }.destroy
    else
      @resident.update_attribute(:deleted_at, Time.now)
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  def tickets
    @tickets = @resident.tickets.includes(:property, :assigner, :assignee, :category, :assets)
    @tickets = @tickets.where(:property_id => @property.id) if @property

    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/resident_tickets.json.rabl")
      }
    end
  end
  
  def roommates
    @roommates = [] # must assign array manually, otherwise curr_property will not work on rabl view
    
    Resident.ordered("first_name asc").where("properties" => {
      "$elemMatch" => { 
        "property_id" => @property.id.to_s, 
        "unit_id" => @resident.curr_property.unit_id.to_s, 
        "roommate" => true
      }
    }).each do |r|
      r.curr_property_id = @property.id
      @roommates << r
    end
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/resident_roommates.json.rabl")
      }
    end
  end
  
  def properties
    @properties = @resident.properties
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/resident_properties.json.rabl")
      }
    end
  end
  
  # for add new ticket page
  def search
    if params[:search].include?("@")
      @resident = Resident.where(:email_lc => params[:search]).first
    else
      @resident = Resident.where(:_id => params[:search]).first
    end
    
    render  :json => {:resident_path => @resident ? property_resident_path(@property, @resident, :anchor => "addTicket") : nil }
  end
  
  # marketing stream (aka x-ray)
  def marketing_statuses
    l2l_sources = []
    l2l_changed_sources = []

    yardi_sources = []
    yardi_changed_sources = []
    
    # collect l2l source source
    @resident.sources.where(:property_id => params[:prop_id]).each_with_index do |s, i|
      pp "#{s.status}, #{s.resident_status}, #{s.status_date}, #{s.created_at}"
      if !s.status.blank? && !s.status_date.blank?
        l2l_sources << {
          :status => "#{s.status} Prospect",
          :status_date => s.status_date
        }
      end

      if s.resident_status
        yardi_sources << {
          :status => "#{s.resident_status} Resident",
          :status_date => s.created_at,
          :move_in => s.move_in,
          :move_out => s.move_out
        }
      end
    end

    #collect only l2l changed source (status & status_date changed)
    #  must order by status_date asc, status_date always exists
    sorted_sources = l2l_sources.sort{|a, b| a[:status_date] <=> b[:status_date] }
    sorted_sources.each_with_index do |s, i|
      if i == 0
        l2l_changed_sources << s

      elsif s[:status] != sorted_sources[i-1][:status]
        l2l_changed_sources << s

      end
    end

    #collect only l2l changed source (status & status_date changed)
    #  must order by status_date asc, status_date always exists
    sorted_sources = yardi_sources.sort{|a, b| a[:status_date] <=> b[:status_date] }
    sorted_sources.each_with_index do |s, i|
      if i == 0
        yardi_changed_sources << s

      elsif s[:status] != sorted_sources[i-1][:status]
        yardi_changed_sources << s

      end
    end

    @statuses = (l2l_changed_sources + yardi_changed_sources).sort{|a, b| b[:status_date] <=> a[:status_date] }
    
    render :json => @statuses.collect{|n| 
      {
        :status => n[:status],
        :status_date => n[:status_date].to_s(:utc_date),
        :move_in => pretty_move_in(n[:move_in]),
        :move_out => pretty_move_in(n[:move_out])
      }
    }
  end
  
  def marketing_properties
    @properties = @residents.properties

    #eager load properties
    properties = Property.where(:id => @properties.collect{|p| p.property_id }.compact).collect{|prop| prop }

    @properties = @properties.collect{|p|
      p.property = properties.detect{|prop| prop.id == p.property_id.to_i}
      p.property ? p : nil
    }.compact.sort{|a, b| a.property.name <=> b.property.name }
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/marketing_properties.json.rabl")
      }
    end
  end

  private
    def resident_params
      params.require(:resident).permit!
    end
    
    def set_property
      if params[:property_id]
        @property = current_user.managed_properties.find(params[:property_id])
        Time.zone = @property.setting.time_zone
      end
    end

    def set_resident
      @resident = Resident.find(params[:id])
      @resident.curr_property_id = @property.id if @property
      
      case action_name
        when "create"
          authorize! :cud, Resident
          
        when "edit", "update", "destroy"
          authorize! :cud, @resident
          
        else
          authorize! :read, @resident
      end
    end
    
    def set_page_title
      if @property
        @page_title = "CRM - #{@property.name} - Residents" 
      else
        @page_title = "CRM - Residents" 
      end
    end
    
    # temp
    def pretty_move_in(date_str)
      date = DateTime.strptime(date_str, '%Y%m%d') rescue nil

      if !date
        date = DateTime.strptime(date_str, '%Y/%m/%d') rescue nil
      end

      if !date
        date = DateTime.strptime(date_str, '%m/%d/%Y') rescue nil
      end

      date.to_s(:utc_date) rescue date_str
    end

    def filter_residents(per_page = 15)
      conditions = {}
      hint = {"properties.property_id" => 1, "properties.status" => 1 }
      
      conditions["properties.property_id"] = @property.id.to_s if @property
      conditions["properties.status"] = {'$in' => ["Current", "Future", "Notice", "Past"]}
      
      if !params[:email].blank?
        conditions[:email_lc] = params[:email].downcase
      end
      
      if !params[:first_name].blank?
        conditions[:first_name_lc] = params[:first_name].downcase
      end
      
      if !params[:last_name].blank?
        conditions[:last_name_lc] = params[:last_name].downcase
      end
      
      if !params[:primary_phone].blank?
        conditions[:primary_phone] = params[:primary_phone]
      end
      
      if !params[:resident_id].blank?
        conditions[:_id] = params[:resident_id]
      end
      
      if !params[:unit_id].blank?
        unit_id = params[:unit_id]
        
        # find unit_id  by unit code
        if unit_id.to_i < 1000*1000*1000 && @property
          unit_id = Unit.where(:property_id => @property.id, :code => unit_id).first.id.to_s rescue unit_id
        end
        
        conditions["properties.unit_id"] = unit_id
      end
      
      if conditions[:first_name_lc] # search first name
        hint = {:first_name_lc => 1}
      end
      
      if conditions[:last_name_lc] # search last name
        hint = {:last_name_lc => 1}
      end
      
      if conditions[:email_lc] #search by email
        hint = {:email_lc => 1}
      end
      
      if conditions[:_id] #search by email
        hint = {}
      end

      @residents = Resident.where(conditions).ordered("updated_at desc")

      # specify the index explicitly
      @residents = @residents.extras(:hint => hint) if !hint.empty?
      
      #pp ">>>>", @residents.limit(25).explain
      @residents = @residents.paginate(:page => params[:page], :per_page => per_page)
      
      if @property
        @residents.each do |r|
          r.curr_property_id = @property.id
        end
      end
    end
    
end