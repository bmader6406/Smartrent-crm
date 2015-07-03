class ProfilesController < ApplicationController
  before_action :require_user
  before_action :set_page_title
  
  def update
    user_params[:enable_validation] = true

    respond_to do |format|       
      if current_user.update_attributes(user_params)
        format.html{
          flash[:notice] = "Profile was successfully updated"
          redirect_to :action => :show
        }
      else
        format.html { render :action => :show }
      end      
    end
  end
  
  private
  
    def user_params
      params.require(:user).permit(:full_name, :email, :password, :password_confirmation, :time_zone)
    end
    
    def set_page_title
      @page_title = "CRM - Profile"
    end
  
end
