class NotificationsController < ApplicationController
  before_action :require_user
  before_action :set_notification, :except => [:index, :new, :create]
  before_action :set_page_title
  
  def index
    
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        filter_notifications(params[:per_page])
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
    @notification = Notification.new(notification_params)
    @notification.owner = current_user
    @notification.last_actor = current_user
    
    respond_to do |format|
      if @notification.save
        format.json { render template: "notifications/show.json.rabl", status: :created }
      else
        format.json { render json: @notification.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
    @notification.last_actor = current_user
    
    respond_to do |format|
      if @notification.update_attributes(notification_params)
        format.json { head :no_content }
      else
        format.json { render json: @notification.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @notification.update_attribute(:deleted_at, Time.now)
    
    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  private
    
    def notification_params
      params.require(:notification).permit!
    end
    
    def set_notification
      @notification = current_user.notifications.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, Notification
          
        when "edit", "update", "destroy"
          authorize! :cud, @notification
          
        else
          authorize! :read, @notification
      end
    end
    
    def set_page_title
      @page_title = "CRM - Notifications" 
    end
    
    def filter_notifications(per_page = 15)
      arr = []
      hash = {}
      
      ["property_id", "resident_id", "subject", "message", "state"].each do |k|
        next if params[k].blank?
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @notifications = current_user.notifications.includes(:property).where(arr.join(" AND "), hash).order('created_at desc').paginate(:page => params[:page], :per_page => per_page)
      
      # eager load residents
      rids = @notifications.collect{|n| n.resident_id.to_s }
      uids = []
      
      if !rids.empty?
        residents = Resident.where(:id.in => rids).collect{|r| r } # don't use .all
        @notifications.each do |n|
          r = residents.detect{|r| n.resident_id == r._id.to_i }
          if r
            r.property_id = n.property_id
            n.eager_load(r)
            
            uids << r.unit_id #must be after property_id is set
          end
        end
        
        # eager load units
        units = Unit.where(:id => uids).all
        residents.each do |r|
          u = units.detect{|u| u.id == r.unit_id.to_i }
          r.eager_load(u) if u
        end
      end
      
    end
end