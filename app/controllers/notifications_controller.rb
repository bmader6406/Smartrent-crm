class NotificationsController < ApplicationController
  before_action :require_user
  before_action :set_property
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
    @notification = @property.notifications.new(notification_params)
    
    respond_to do |format|
      if @notification.save
        format.json { render template: "notifications/show.json.rabl", status: :created }
      else
        format.json { render json: @notification.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
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
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      
      Time.zone = @property.setting.time_zone
    end

    def set_notification
      @notification = @property.notifications.find(params[:id])
      
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
      @page_title = "CRM - #{@property.name} - Notifications" 
    end
    
    def filter_notifications(per_page = 15)
      arr = []
      hash = {}
      
      ["name"].each do |k|
        next if params[k].blank?
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @notifications = @property.notifications.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page)
    end
end