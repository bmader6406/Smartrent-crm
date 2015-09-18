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
  
  def acknowledge
    @notification.last_actor = current_user
    @notification.state = "acknowledged"
    
    respond_to do |format|
      if @notification.save
        format.json { render template: "notifications/show.json.rabl", status: :updated }
      else
        format.json { render json: @notification.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  def reply
    @notification.last_actor = current_user
    @notification.state = "replied"
    
    respond_to do |format|
      if @notification.save
        
        create_email_activity
        
        format.json { render template: "notifications/show.json.rabl", status: :updated }
      else
        format.json { render json: @notification.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  private
    
    def notification_params
      params.require(:notification).permit!
    end
    
    def comment_params
      params.require(:comment).permit!
    end

    def email_params
      params.require(:email).permit!
    end
    
    def create_email_activity
      @property = Property.find(params[:property_id])

      @resident = Resident.find(params[:resident_id])
      @resident.curr_property_id = @property.id if @property


      @activity = @resident.activities.new

      comment = comment_params.clone

      comment[:property_id] = @property.id
      comment[:resident_id] = @resident.id
      comment[:author_id] = current_user.id
      comment[:author_type] = current_user.class.to_s

      @comment = Comment.new(comment)


      @comment.build_email(email_params)

      if @comment.save
        # should assign id/type manually
        @activity.action = @comment.type
        @activity.subject_id = @comment.id
        @activity.subject_type = @comment.class.to_s
        @activity.property_id = @property.id if @property
      end
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
      
      ["property_id", "resident_id", "message", "state"].each do |k|
        next if params[k].blank?
        arr << "#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @notifications = current_user.notifications.where(arr.join(" AND "), hash).order('created_at desc').paginate(:page => params[:page], :per_page => per_page)
    end
end