class UserSessionsController < ApplicationController
  before_action :require_ssl
  before_action :require_no_user, :only => [:new, :create]
  before_action :require_user, :only => :destroy
  before_action :set_page_title

  layout "login"

  def new
    @user_session = UserSession.new
  
    if params[:token]
      session[:invite_token] = params[:token]
      @invite = Manager.find_by_token(params[:token])
    end
    
  end

  def create
    @user_session = UserSession.new(user_session_params)
    if @user_session.save
      flash[:notice] = "Signed in successfully."
    
      redirect_to accept_invite_and_redirect(UserSession.find.record, session[:invite_token]) || back_or_default_url( root_url(:protocol => "http") )
    else
      render :action => 'new'
    end
  end

  def destroy
    current_user_session.destroy
    redirect_to login_url, :notice => "Logged out successfully"
  end
  
  private
    
    def user_session_params
      params.require(:user_session).permit(:email, :password)
    end
    
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :terms_of_service)
    end
    
    def set_page_title
      @page_title = "CRM - Login"
    end
    
end