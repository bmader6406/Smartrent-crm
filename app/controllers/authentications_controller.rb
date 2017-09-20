class AuthenticationsController < ApplicationController
  # before_action :require_ssl
  before_action :require_user, :only => [:destroy, :index]
  
  def create
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    
    logged_in_url = params[:redirect_to] || root_url

    if authentication #existing auth
      authentication.oauth_token = omniauth['credentials']["token"]
      authentication.oauth_secret = omniauth['credentials']["secret"]
      authentication.save
      
      if !current_user
        if authentication.user.active?
          flash[:notice] = "Signed in successfully."
          UserSession.create(authentication.user)
          
          redirect_to accept_invite_and_redirect(authentication.user, session[:invite_token]) || back_or_default_url(logged_in_url)
        else
          flash[:error] = "Sorry, your account has been deactivated"
          redirect_to login_url
        end
        
      else
        flash[:alert] = "Authentication has been already added!"
        redirect_to profile_url
      end
      
    elsif current_user #add new auth
      current_user.authentications.create({
        :provider => omniauth['provider'],
        :uid => omniauth['uid'],
        :name => omniauth['info']["name"],
        :oauth_token => omniauth['credentials']["token"], 
        :oauth_secret => omniauth['credentials']["secret"]
      })
        
      flash[:notice] = "Authentication was added successfully."
      redirect_to profile_url
      
    end
  end
  
  def failure
    flash[:error] = "There was a problem, please try again"
    
    if current_user
      redirect_to profile_url
    else
      redirect_to login_url
    end
  end
  
  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully removed authentication."
    redirect_to profile_url
  end
end
