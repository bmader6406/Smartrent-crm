class TicketsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_ticket, :except => [:index, :new, :create]
  before_action :set_page_title
  before_action :set_unit, :only => [:index]
  before_action :set_resident, :only => [:show]
  
  def index

    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_tickets(params[:per_page])
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
    asset_ids = ticket_params[:asset_ids].split(",").collect{|i| i.strip if !i.blank? }.compact rescue []
    remove_asset_ids = ticket_params[:remove_asset_ids].split(",").collect{|i| i.strip if !i.blank? }.compact rescue []
    #must delete
    ticket_params.delete(:assets)
    ticket_params.delete(:asset_ids)
    ticket_params.delete(:remove_asset_ids)

    @ticket = Ticket.new(ticket_params)
    @ticket.assigner_id = current_user.id
    @ticket.property_id = @property.id
    
    @ticket.author = current_user
    @ticket.action = "new_ticket"
    
    respond_to do |format|
      if @ticket.save
        if !remove_asset_ids.empty?
          @property.assets.where(:id => remove_asset_ids).update_all(:ticket_id => nil) #remove
        end
        
        if !asset_ids.empty?
          @property.assets.where(:id => asset_ids).update_all(:ticket_id => @ticket.id) #add new
        end
        
        format.json { render template: "tickets/show.json.rabl", status: :created }
      else
        format.json { render json: @ticket.errors.full_messages, status: :unprocessable_entity }
      end
    end

  end

  def update
    asset_ids = ticket_params[:asset_ids].split(",").collect{|i| i.strip if !i.blank? }.compact rescue []
    remove_asset_ids = ticket_params[:remove_asset_ids].split(",").collect{|i| i.strip if !i.blank? }.compact rescue []
    #must delete
    ticket_params.delete(:assets)
    ticket_params.delete(:asset_ids)
    ticket_params.delete(:remove_asset_ids)
    
    @ticket.author = current_user
    
    respond_to do |format|
      if @ticket.update_attributes(ticket_params)
        if !remove_asset_ids.empty?
          @property.assets.where(:id => remove_asset_ids).update_all(:ticket_id => nil) #remove
        end
        
        if !asset_ids.empty?
          @property.assets.where(:id => asset_ids).update_all(:ticket_id => @ticket.id) #add new
        end
        
        format.json { head :no_content }
      else
        format.json { render json: @ticket.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @ticket.update_attribute(:deleted_at, Time.now)

    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  private
    
    def ticket_params
      params.require(:ticket).permit!
    end
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      Time.zone = @property.setting.time_zone
    end

    def set_unit
      @unit = @property.units.find(params[:unit_id]) if params[:unit_id].present?
    end

    def set_resident
      # params[:resident_id] is a pair of resident id and unit id
      if params[:resident_id].present?
        resident_id, unit_id = params[:resident_id].split("_", 2)
      
        @resident = Resident.find(resident_id)
        @unit = @property.units.find(unit_id)
      
        @resident.curr_unit_id = @unit.id # important
      end
    end

    def set_ticket
      @ticket = @property.tickets.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, Ticket
          
        when "edit", "update", "destroy"
          authorize! :cud, @ticket
          
        else
          authorize! :read, @ticket
      end
    end
    
    def set_page_title
      @page_title = "CRM - #{@property.name} - Tickets" 
    end
    
    def filter_tickets(per_page = 15)
      arr = []
      hash = {}
      
      if !params[:unit_code].blank? #convert unit code to unit id
        params[:unit_id] = @property.units.find_by_code(params[:unit_code]) rescue nil
      end
      
      ["id", "unit_id", "status"].each do |k|
        next if params[k].blank?
        arr << "#{k} = :#{k}"
        hash[k.to_sym] = params[k]
      end
      
      start_date = Date.parse(params[:start_date]) rescue nil
      end_date = Date.parse(params[:end_date]) rescue nil
      
      if start_date && end_date
        arr << "created_at >= :start_date AND created_at <= :end_date"
        hash[:start_date] = start_date.to_s(:db)
        hash[:end_date] = end_date.to_s(:db)
        
      elsif start_date
        arr << "created_at >= :start_date"
        hash[:start_date] = start_date.to_s(:db)
        
      elsif end_date
        arr << "created_at <= :end_date"
        hash[:end_date] = end_date.to_s(:db)
      end
      
      if !params[:first_name].blank? || !params[:last_name].blank? || !params[:email].blank?
        residents = Resident
        residents = residents.where(:first_name_lc => params[:first_name].downcase) if !params[:first_name].blank?
        residents = residents.where(:last_name_lc => params[:last_name].downcase) if !params[:last_name].blank?
        residents = residents.where(:email_lc => params[:email].downcase) if !params[:email].blank?
        
        arr << "resident_id IN (:resident_id)"
        hash[:resident_id] = residents.collect{|r| r._id.to_i }
      end
      
      if @unit.present?
        unit_resident_ids = @unit.residents.collect{|r| r.id}
        @tickets = @property.tickets.where(:resident_id => unit_resident_ids).where("status = ? or (status != ? and created_at >= ?)", "open", "open", Time.now - 2.months)
        
      else
        @tickets = @property.tickets
      end
      
      @tickets = @tickets.includes(:property, :unit, :assigner, :assignee, :category, :assets).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page)
      
      # eager load residents
      rids = @tickets.collect{|t| t.resident_id.to_s }
      if !rids.empty?
        residents = Resident.where(:id.in => rids).collect{|r| r } # don't use .all
        @tickets.each do |t|
          r = residents.detect{|r| t.resident_id == r._id.to_i }
          if r
            r.property_id = t.property_id
            t.eager_load(r)
          end
        end
      end
      
    end
end
