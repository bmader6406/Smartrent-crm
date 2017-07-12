class PasswordResetsController < ApplicationController
  # before_action :require_ssl
  before_action :require_no_user
  before_action :set_page_title
  before_action :set_user_by_perishable_token, :only => [:edit, :update]

  layout "login"

  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user
      @user.deliver_password_reset!
      flash.now[:notice] = "Instructions to reset your password have been emailed to you. Please check your email."
      render :action => :new
    else
      flash.now[:alert] = "No user was found with that email address"
      render :action => :new
    end
  end

  def edit
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save_without_session_maintenance
      @user.deliver_password_change!
      flash[:notice] = "Password successfully reseted"
      redirect_to login_url
    else
      render :action => :edit
    end
  end

  private
    def set_user_by_perishable_token
      @user = User.find_using_perishable_token(params[:id], 2.hour)
      unless @user
        flash.now[:alert] = "We're sorry, but we could not locate your account." +
          "If you are having issues try copying and pasting the URL " +
          "from your email into your browser or restarting the " +
          "reset password process."
        render :action => :new and return
      end
    end
  
    def set_page_title
      @page_title = "CRM - Reset Password"
    end
end