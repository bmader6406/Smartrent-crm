class UsersController < ApplicationController
  before_action :require_user
  before_action :set_user, :except => [:index, :new, :create]
  before_action :set_page_title
  
  def index
    
    respond_to do |format|
      format.html {
        render :file => "users/index"
      }
      format.json {
        filter_users(params[:per_page])
      }
    end
  end

  def show
    
    respond_to do |format|
      format.html {
        render :file => "users/index"
      }
      format.json {}
    end
  end
  
  def new
    respond_to do |format|
      format.html {
        render :file => "users/index"
      }
      format.json {}
    end
  end
  
  def edit
    respond_to do |format|
      format.html {
        render :file => "users/index"
      }
      format.json {}
    end
  end
  
  def create
    attrs = {} # IMPORTANT these attrs are allowed on users creation only
    [:first_name, :last_name, :email, :password, :password_confirmation].each do |k|
      attrs[k] = user_params[k]
    end
    
    if attrs[:password].blank?
      attrs.delete(:password)
      attrs.delete(:password_confirmation)
    end
    
    @user = User.find_by_email(user_params[:email])

    if !@user
      @user = User.new(attrs)
    end
    
    respond_to do |format|
      if @user.save
        revoke_and_grant
        
        format.json { render template: "users/show.json.rabl", status: :created }
      else
        format.json { render json: @user.errors.full_messages, status: :unprocessable_entity }
      end
    end
    
  end

  def update
    # not update existing user info
    respond_to do |format|
      if true
        revoke_and_grant
        format.json { render template: "users/show.json.rabl" }
      else
        format.json { render json: @user.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @user.remove_role params[:role], @property
    revoke
    
    respond_to do |format|
      format.json { head :no_content }
    end
  end
  
  private
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation,
        :role, :authorized_property_ids => [], :authorized_region_ids => [])
    end
    
    def set_user
      @user = User.find_by_id(params[:id])

      case action_name
        when "create"
          authorize! :cud, User
          
        when "edit", "update", "destroy"
          if current_user != @user
            authorize! :cud, @user
          end
          
        else
          authorize! :read, @user
      end
      
      if action_name == "edit" && @user.id == current_user.id
        redirect_to profile_path and return
      end
    end
    
    def set_page_title
      @page_title = "CRM - Accounts"
    end
    
    def revoke
      UserRole.where(:user_id => @user.id).delete_all
    end
    
    def grant
      # top level role
      @user.add_role user_params[:role], Property
      
      # regional or property level role
      if user_params[:role] == "regional_manager"
        Region.where(:id => user_params[:authorized_region_ids]).each do |region|
          @user.add_role "manager", region
        end
      else
        Property.where(:id => user_params[:authorized_property_ids]).each do |property|
          @user.add_role "manager", property
        end
      end
    end
    
    def revoke_and_grant
      revoke
      grant
    end
    
    def filter_users(per_page = 15)
      arr = []
      hash = {}
      
      ["id", "first_name", "last_name", "email"].each do |k|
        next if params[k].blank?
        arr << "users.#{k} LIKE :#{k}"
        hash[k.to_sym] = "%#{params[k]}%"
      end
      
      @users = User.joins(:roles).distinct("users.id").includes(:roles => :resource).where(arr.join(" AND "), hash)
      
      if !params[:role].blank?
        @users = @users.where("roles.name = ?", params[:role])
      end
      
      if params[:authorized_for].to_i > 0
        @users = @users.where("roles.resource_type" => ["Property", "Region"], "roles.resource_id" => params[:authorized_for].to_i)
        
      elsif params[:authorized_for] == "all"
        @users = @users.where("roles.name" => "admin", "roles.resource_type" => "Property")
        
      end
      
      @users = @users.order("users.first_name asc").paginate(:page => params[:page], :per_page => per_page)
    end
end