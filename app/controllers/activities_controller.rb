class ActivitiesController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_resident
  before_action :set_activity, :except => [:index, :new, :create]
  before_action :set_page_title
  
  def index
    respond_to do |format|
      format.html {
        render :file => "dashboards/index"
      }
      format.json {
        @activities = []
        
        if params[:history] == "resident"
          @activities = filter_activities("resident")
          
        elsif params[:history] == "marketing"
          @activities = filter_activities("marketing")
          
        end
        
        # manual eager load
        if params[:history] == "resident"
          subject = {}
          author = {}
          @activities.each do |a|
            if a.subject_id
              if subject["#{a.subject_type}"]
                subject["#{a.subject_type}"] << a.subject_id
              else
                subject["#{a.subject_type}"] = [a.subject_id]
              end
            end
          
            if a.author_id # ticket author hack
              if subject["#{a.author_type}"]
                subject["#{a.author_type}"] << a.author_id
              else
                subject["#{a.author_type}"] = [a.author_id]
              end
            end
          end
        
          # cache subjects
          #pp "subject: ", subject
          subject.keys.each do |k|
            if k == "Comment"
              comments = Comment.where(:id => subject[k].uniq).includes(:email, :call, :assets)
              comments.each do |c|
                if c.author_id
                  if author["#{c.author_type}"]
                    author["#{c.author_type}"] << c.author_id
                  else
                    author["#{c.author_type}"] = [c.author_id]
                  end
                end
              end
            
              # cache authors
              author.keys.each do |k2|
                if k2 == "Resident"
                  Resident.where(:_id => author[k2].uniq).each do |r|
                    author["#{k2}_#{r.id}"] = r
                  end
                
                elsif k2 == "User"
                  User.where(:id => author[k2].uniq).each do |u|
                    author["#{k2}_#{u.id}"] = u
                  end
                end
              end
            
              comments.each do |c|
                c.eager_load(author["#{c.author_type}_#{c.author_id}"])
                subject["#{k}_#{c.id}"] = c
              end
            
            elsif k == "Ticket"
              Ticket.where(:id => subject[k].uniq).includes(:assigner, :assignee).each do |t|
                subject["#{k}_#{t.id}"] = t
              end
            
            elsif k == "User" # ticket author hack
              User.where(:id => subject[k].uniq).each do |u|
                subject["#{k}_#{u.id}"] = u
              end
            
            end
          end
        
          @activities.each do |a|
            a.eager_load(subject["#{a.subject_type}_#{a.subject_id}"])
            a.eager_load(subject["#{a.author_type}_#{a.author_id}"])
          end
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
    @activity = @resident.activities.new
    
    comment = comment_params.clone
    
    comment[:property_id] = @property.id
    comment[:resident_id] = @resident.id
    comment[:author_id] = current_user.id
    comment[:author_type] = current_user.class.to_s
    
    comment[:message] = params[:call][:message] if params[:call]
    
    @comment = Comment.new(comment)
    
    if comment[:type] == "phone"
      # TODO: validate contact before calling activities#create
      # contact = Contact.new
      # contact.phone = params[:to]
      #       
      # if contact.valid? || params[:to].to_s.gusb(" ", "") == "+84909196997"
      # 
      # else
      #   # Oops there was an error, lets return the validation errors
      #   @msg = { :message => contact.errors.full_messages, :status => 'ok' }
      # end
      
      twilio_client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
      
      #:call_as is the property owner
      call_as = params[:call][:call_as] || TWILIO_NUMBER
      
      # Connect an outbound call to the number submitted
      twilio_call = twilio_client.account.calls.create({
        :application_sid => TWILIO_P2P_SID,
        :timeout => 60,
        :from => call_as,
        :to => params[:call][:from], #call :from (agent) first, then call :to (prospect)
        :record => true
      })
      
      # save to history
      @comment.build_call({
        :from => call_as,
        :to => params[:call][:to], #call prospect on twilio callback
        :origin_id => twilio_call.sid
      })
      
    elsif comment[:type] == "email"
      @comment.build_email(email_params)
      
    end
    
    if @comment.save
      # should assign id/type manually
      @activity.action = @comment.type
      @activity.subject_id = @comment.id
      @activity.subject_type = @comment.class.to_s
      @activity.property_id = @property.id if @property
      
      if comment[:asset_ids] 
        @property.assets.where(:id => comment[:asset_ids].split(",")).update_all(:comment_id => @comment.id)
      end
    end
    
    respond_to do |format|
      if !@comment.errors.empty?
        format.json { render json: @comment.errors.full_messages, status: :unprocessable_entity }
        
      elsif @activity.save
        format.json { render template: "activities/show.json.rabl", status: :created }
        
      else
        format.json { render json: @activity.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @activity.update_attributes(activity_params)
        format.json { head :no_content }
      else
        format.json { render json: @activity.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @activity.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private
  
    def activity_params
      params.require(:activity).permit!
    end
    
    def comment_params
      params.require(:comment).permit!
    end
    
    def email_params
      params.require(:email).permit!
    end
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      Time.zone = @property.setting.time_zone
    end
    
    def set_resident
      @resident = Resident.find(params[:resident_id])
      @resident.curr_property_id = @property.id
    end

    def set_activity
      @activity = @resident.activities.find(params[:id])
      
      case action_name
        when "create"
          authorize! :cud, ResidentActivity
          
        when "edit", "update", "destroy"
          authorize! :cud, @activity
          
        else
          authorize! :read, @activity
      end
    end
    
    def set_page_title
      @page_title = "CRM - #{@property.name} - Activities" 
    end

    def filter_activities(history)
      params[:page] = 1 if !params[:page]
      per_page = (params[:per_page] || 20).to_i
      skip = (params[:page].to_i - 1) * per_page
      #pp "per_page: #{per_page}, skip: #{skip}"
      
      activities = []
      
      if history == "resident"
        @resident.activities.where(:property_id => @property.id).order_by(:created_at => :desc).skip(skip).limit(per_page).each do |a|
          next if !a.subject_type
          activities << a
        end
        
      elsif history == "marketing"
        counted = {} # count marker
        
        # load each 100 for marketing
        per_page = 100
        skip = (params[:page].to_i - 1) * per_page
        
        @resident.marketing_activities.where(:property_id => @property.id).order_by(:created_at => :desc).skip(skip).limit(per_page).each do |a|
          next if !a.subject_type

          # ignore counted activity
          next if counted["#{a.action}_#{a.subject_id}"]

          # ignore all autoresponder history
          next if ["send_mail", "open_mail", "click_link"].include?(a.action) && !["NewsletterCampaign"].include?(a.subject_type)

          activities << a

          #mark as counted
          counted["#{a.action}_#{a.subject_id}"] = 1
        end

        
      end #/ marketing
      
      activities
    end
    
end