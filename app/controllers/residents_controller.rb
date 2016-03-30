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
      if resident_params[f]
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
    unit_attrs = {
      :property_id => params[:property_id]
    }
    
    Resident::UNIT_FIELDS.each do |f|
      unit_attrs[f] = resident_params[f] if !resident_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && unit_attrs[f]
        unit_attrs[f] = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
      end
    end

    respond_to do |format|
      if @resident.save
        #create a source to keep this history
        # property record will create right after source created vi callback
        @resident.sources.create(unit_attrs) if unit_attrs[:property_id]
        
        format.json { render template: "residents/show.json.rabl", status: :created }
      else
        format.json { render json: @resident.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    Resident::CORE_FIELDS.each do |f|
      if resident_params[f]
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
    unit_attrs = {
      :property_id => params[:property_id]
    }
    
    Resident::UNIT_FIELDS.each do |f|
      unit_attrs[f] = resident_params[f] if !resident_params[f].blank?
      
      if [:signing_date, :move_in, :move_out].include?(f) && unit_attrs[f]
        unit_attrs[f] = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
      end
    end

    respond_to do |format|
      if @resident.save
        @resident.sources.create(unit_attrs)  if unit_attrs[:property_id]
        format.json { render template: "residents/show.json.rabl" }
      else
        format.json { render json: @resident.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @property
      @resident.units.detect{|u| u.property_id.to_i == @property.id }.destroy
    else
      @resident.update_attribute(:deleted_at, Time.now)
    end

    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  def tickets
    @tickets = @resident.tickets.includes(:property, :assigner, :assignee, :category, :assets)
    @tickets = @tickets.where(:property_id => @property.id, :unit_id => @resident.unit_id) if @property

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
    @roommates = [] # must assign array manually, otherwise curr_unit will not work on rabl view

    Resident.ordered("first_name asc").where("units" => {
      "$elemMatch" => {
        "property_id" => @property.id.to_s,
        "unit_id" => @resident.unit_id.to_s,
        "status" => "Current"
      }
    }).each do |r|
      r.curr_unit_id = @resident.unit_id.to_s
      @roommates << r
    end
    
    primary_residents = []
    roommates = []
    
    @roommates.each do |r|
      if r.curr_unit.roommate?
        roommates << r
      else
        primary_residents << r
      end
    end
    
    @roommates = primary_residents + roommates
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/resident_roommates.json.rabl")
      }
    end
  end
  
  def units
    @units = @resident.units.sort{|a, b| b.move_in <=> a.move_in }
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/resident_units.json.rabl")
      }
    end
  end

  def smartrent
    @smartrent_resident = @resident.smartrent_resident
  end
  
  # for add new ticket page
  def search
    col_dict = {
      :unit_code => "0",
      :name => "1",
      :email => "2"
    }
    
    if params[:filter]
      col_dict.keys.each do |k|
        search = params[:filter][ col_dict[k] ]
        next if search.blank?
        
        if k == :name
          fn, ln = search.split(" ", 2)
          
          if !ln.blank?
            params[:first_name] = fn
            params[:last_name] = ln
            
          else
            params[:first_name] = fn
          end
          
        else
          params[k] = search
        end
        
      end
    end
    
    # tablesorter page index start with 0
    params[:page] = params[:page].to_i + 1
    
    filter_residents(10)
    
    #render  :json => {:resident_path => @resident ? property_resident_path(@property, @resident, :anchor => "addTicket") : nil }
    
    render template: "residents/table.json.rabl" 
    
  end
  
  # marketing stream (aka x-ray)
  def marketing_statuses
    sources = []
    changed_sources = []

    
    # collect l2l source source
    @resident.sources.where(:property_id => params[:prop_id]).each_with_index do |s, i|
      pp "#{s.status}, #{s.status_date}, #{s.created_at}"
      if s.status
        sources << {
          :status => s.status,
          :status_date => s.created_at,
          :move_in => s.move_in,
          :move_out => s.move_out
        }
      end
    end

    #collect only changed source (status & status_date changed)
    #  must order by status_date asc, status_date always exists
    sorted_sources = sources.sort{|a, b| a[:status_date] <=> b[:status_date] }
    sorted_sources.each_with_index do |s, i|
      if i == 0
        changed_sources << s

      elsif s[:status] != sorted_sources[i-1][:status]
        changed_sources << s

      end
    end


    @statuses = changed_sources.sort{|a, b| b[:status_date] <=> a[:status_date] }
    
    render :json => @statuses.collect{|n| 
      {
        :status => n[:status],
        :status_date => n[:status_date].to_s(:utc_date),
        :move_in => pretty_move_in(n[:move_in]),
        :move_out => pretty_move_in(n[:move_out])
      }
    }
  end
  
  def marketing_units
    @units = @resident.units

    #eager load units
    properties = Property.where(:id => @units.collect{|u| u.property_id }.compact).collect{|prop| prop }

    @units = @units.collect{|u|
      u.property = properties.detect{|prop| prop.id == u.property_id.to_i}
      u.property ? t : nil
    }.compact.sort{|a, b| a.property.name <=> b.property.name }
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        render(template: "residents/marketing_units.json.rabl")
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
      
      else
        if !current_user.has_role? :admin, Property
          
          if current_user.managed_properties.first
            redirect_to property_residents_url(current_user.managed_properties.first) and return

          else
            redirect_to profile_url and return
          end
          
        end
      end
    end

    def set_resident
      # params[:id] is a pair of resident id and unit id OR don't have _unit_id
      resident_id, unit_id = params[:id].split("_", 2)
      
      @resident = Resident.find(resident_id)
      
      # resident listing and details support both org group and property level
      if @property && unit_id
        @unit = @property.units.find(unit_id)
        @resident.curr_unit_id = @unit.id # important
      end
      
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
        if @resident
          @page_title = "CRM - Resident - #{@resident.name_or_email}"
          
        else
          @page_title = "CRM - #{@property.name} - Residents"
        end
        
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
      match = {}
      
      match["units.property_id"] = @property.id.to_s if @property
      
      if !params[:email].blank?
        match[:email_lc] = params[:email].downcase
      end
      
      if !params[:first_name].blank?
        match[:first_name_lc] = params[:first_name].downcase
      end
      
      if !params[:last_name].blank?
        match[:last_name_lc] = params[:last_name].downcase
      end
      
      if !params[:primary_phone].blank?
        match[:primary_phone] = params[:primary_phone]
      end
      
      if !params[:resident_id].blank?
        match[:_id] = params[:resident_id]
      end
      
      if !params[:unit_code].blank?
        unit_id = Unit.where(:property_id => @property.id, :code => params[:unit_code]).first.id.to_s rescue -1
        match["units.unit_id"] = unit_id
      end
      
      if !params[:status].blank?
        match["units.status"] = params[:status]
      end
      
      if params[:roommate] == "0"
        match["units.roommate"] = {"$in" => [nil, false] }
      end
      
      if params[:roommate] == "1"
        match["units.roommate"] = true
      end
      
      # manual paging
      limit = params[:page].to_i*per_page.to_i
      skip = limit - per_page.to_i
      
      resident_dict = {} # is used to load resident and their units
      
      project = {
        "email_lc" => 1,
        "first_name_lc" => 1,
        "last_name_lc" => 1,
        "primary_phone" => 1,
        "units._id" => 1,
        "units.unit_id" => 1,
        "units.property_id" => 1,
        "units.status" => 1,
        "units.roommate" => 1
      }
      
      if @property
        pipeline = [
          { "$project" => project },
          { "$match" => {"units.property_id" => @property.id.to_s} },
          { "$unwind" => "$units" }
        ]
        
        if !match.empty?
          pipeline << { "$match" => match }
        end
        
      else
        pipeline = [
          { "$project" => project },
          { "$unwind" => "$units" }
        ]
        
        if !match.empty?
          pipeline << { "$match" => match }
        end
      end
      
      @total_residents = Resident.with(:consistency => :eventual).collection.aggregate(pipeline + [
        { "$group" => { :_id => "$units._id" } },
        { "$group" => { :_id => 1, :count => { "$sum" => 1 } } }
      ])[0]["count"] rescue 0
      
      #pp "@total_residents #{@total_residents}"
      #pp "match, skip, limit", match, limit, skip

      Resident.with(:consistency => :eventual).collection.aggregate(pipeline + [
        { "$sort" => { "first_name" => 1, "last_name" => 1 } },
        { "$limit" => limit },
        { "$skip" => skip }
      ]).each do |hash|
        if resident_dict[ hash["_id"] ]
          resident_dict[ hash["_id"] ] << hash["units"]["unit_id"]
          
        else
          resident_dict[ hash["_id"] ] = [ hash["units"]["unit_id"] ]
        end
      end
      
      @residents = []
      unit_ids = []
      
      #pp ">>> resident_dict", resident_dict

      Resident.with(:consistency => :eventual).without(:sources, :activities).where(:_id.in => resident_dict.keys).each do |r|
        next if !resident_dict[ r._id ]
        
        r.units.each_with_index do |u, j|
          next if !resident_dict[ r._id ].include?( u.unit_id )
          
          # must reload if a resident has multiple units
          if j > 0
            r2 = r
            r = r2.clone # to create new object (memoization workaround), never save the temp record
            r.id = r2.id
          end
          
          r.curr_unit_id = u.unit_id
          @residents << r
          
          unit_ids << u.unit_id
        end
      end
      
      #pp ">>> @residents", @residents
      
      # build smartrent dict
      smartrent_dict = {}
      Smartrent::Resident.where(:email => @residents.collect{|r| r.email }).each do |sr|
        smartrent_dict[sr.email.to_s.downcase] = sr
      end

      units = Unit.includes(:property).where(:id => unit_ids).all
      @property_dict = {}
      
      units.each do |u|
        @property_dict[u.property.id.to_s] = u.property
      end
      
      #pp "@property_dict", @property_dict
      
      @residents.each do |r|
        # eager load smartrent
        r.eager_load( smartrent_dict[r.email_lc] )

        # eager load unit
        r.eager_load(units.detect{|u| u.id == r.curr_unit_id.to_i })
      end
      
    end
    
end
