class DashboardsController < ApplicationController
  before_action :require_user
  before_action :set_page_title
  
  def start #root
    if current_user.managed_properties.first
      redirect_to property_url(current_user.managed_properties.first) and return
      
    elsif current_user.properties.first
      redirect_to property_url(current_user.properties.first) and return
      
    else
      redirect_to profile_url and return
    end
    
    #show Property screen
    @page_title = "Select Property"
    render :layout => "login"
  end

  private
  
    def set_page_title
      @page_title = "CRM - Dashboard"
    end
end
