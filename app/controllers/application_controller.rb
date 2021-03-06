require 'open-uri'
require 'csv'
require 'pp'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  helper :all # include all helpers, all the time
  helper_method :current_user_session, :current_user, :accept_invite_and_redirect, :conversion, :avg, :age
  
  before_action :set_user_time_zone

  before_filter :store_return_to, :check_session_expiry


  rescue_from CanCan::AccessDenied do |exception|
    msg = "Access denied on #{exception.action} #{exception.subject.inspect} - #{current_user.id}"
    ppp msg
    
    respond_to do |format|
      format.html {
        flash[:error] = "You are not authorized to access that page"
        redirect_to main_app.root_url, :alert => "You are not authorized to access that page"
      }
      format.json {
        render :json => {:error => "401 Unauthorized"}, :status => 401
      }
    end
  end

  def after_sign_in_path_for(resource)
    session[:return_to] || root_path
  end

  def store_return_to
    unless request.xhr?
      # Exlude AJAX & Black listed URLs
      unless request.fullpath == '/login' or request.fullpath == '/logout' or request.fullpath == '/user_sessions'
        session[:return_to] = if request.get?
          request.fullpath
        else
          request.referer
        end
      end
    end
    if request.fullpath == '/logout'
      if current_user.is_admin? or current_user.is_property_manager?
          app_domains = ["crm", "crm2", "crm-beta", "crm-live", "crm-dev", "crm-test"]
          if request.subdomain.present? and app_domains.include?(request.subdomain)
            session[:return_to] = '/properties'
          else
            session[:return_to] = '/admin'
          end
      else
          session[:return_to] = nil
      end
    end
  end

  def check_session_expiry
      if request.fullpath == '/login' or request.fullpath == '/logout' or request.fullpath == '/user_sessions'
        # Exclude black-listed URLs
        return true
      end
      if params[:controller] == 'notifications' and (params[:action] == 'index' or params[:action] == 'poll')
        # Exclude notification AJAX calls from session timeout checks
        return true
      end
      #Non-AJAX call, imposing session expiry check
      if session[:absolute_timeout].nil?
        # Set absolute session timeout value
        session[:absolute_timeout] = Rails.configuration.session_absolute_timeout_duration.seconds.from_now.to_i
      end
      if !session[:absolute_timeout].nil? and session[:absolute_timeout] < Time.zone.now.to_i
        force_logout and return false
      end
      if !session[:inactivity_timeout].nil? and session[:inactivity_timeout] < Time.zone.now.to_i
        force_logout and return false
      end
      # Set/Update inactivity session timeout value
      session[:inactivity_timeout] = Rails.configuration.session_inactivity_timeout_duration.seconds.from_now.to_i
      return true
  end

  def force_logout
    return_url = session[:return_to]
    # Clear session and force the user to login screen
    reset_session
    if @current_user_session.present?
      @current_user_session.destroy
    end
    session[:absolute_timeout] = nil
    session[:inactivity_timeout] = nil
    session[:return_to] = return_url
    flash[:error] = "Session timeout! Please login again.";
    respond_to do |format|
      format.html {
        redirect_to session[:return_to]
      }
      format.json {
        render :json => {:status => {:code => 401,  :message => "Session expired"}}, :status => 200
      }
    end
  end
  
  def require_ssl
    if !request.ssl?
      redirect_to({:protocol => 'https', :host => request.env['HTTP_HOST'] }.merge(params)) #, :flash => flash
    end
  end
  
  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  
  #authlogic
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end

  def require_user
    if !current_user
      store_location
      #flash[:error] = "You must be logged in to access this page"
      redirect_to main_app.login_url and return false
      
    else
      if !current_user.active?
        current_user_session.destroy
        flash[:error] = "Sorry, you cannot login because your account has been deactivated."
        redirect_to main_app.login_url and return
      end
    end
  end

  def require_no_user
    if current_user
      store_location
      # click on invite link, auto redirect to the invite org if logged in
      redirect_to accept_invite_and_redirect(current_user, params[:token]) || back_or_default_url( main_app.root_url(:protocol => "http") )
      return false
    end
  end

  def require_admin
    return true if current_user and current_user.is_admin?
    raise CanCan::AccessDenied
  end
      
  def store_location
    unless request.xhr?
      session[:return_to] = request.url
    end
  end
  
  def back_or_default_url(default)
    url = session[:return_to] || default
    if url == login_url || url.include?("login") || url.include?("user_sessions")
      url = default
      session[:return_to] = nil
    end
    session[:return_to] = nil
    url
  end    
  
  def set_user_time_zone
    Time.zone = current_user.time_zone if current_user
  end
  
  def accept_invite_and_redirect(user, token)
    if user && token
    end
    
    return nil
  end
  
  
  # helpers
  def ppp(*args)
    pp ">>>>>>>>>>>>"
    pp ">>>>>>>>>>>>"
    pp args
    pp ">>>>>>>>>>>>"
    pp ">>>>>>>>>>>>"
  end
  
  def age(dob)
    if (dob.year rescue false)
      today = Date.today
      age = today.year - dob.year
      age -= 1 if dob.strftime("%m%d").to_i > today.strftime("%m%d").to_i
      age
    else
      "N/A"
    end
  end
  
  def conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(1)
  end
  
  def avg(total, count)
    count.to_i.zero? ? 0 : total.to_i/count.to_i
  end
  
  def sanitize_grid_cell(arr)
    arr.collect do |str|
      if str.kind_of?(String)
        ActionController::Base.helpers.sanitize(str, :tags => %w(b i u span p em hr div ul ol li img br a), :attributes => %w(style src alt href target class id))
      else
        str
      end
    end
  end
  
end
