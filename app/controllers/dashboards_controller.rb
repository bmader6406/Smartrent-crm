class DashboardsController < ApplicationController
  before_action :require_user
  before_action :set_property, :except => [:start]
  
  def index
    @page_title = "CRM - #{@property.name}"
  end
  
  def start #root
    if current_user.has_role? :admin, Property
      redirect_to properties_url and return
      
    elsif current_user.managed_properties.first
      redirect_to property_residents_url(current_user.managed_properties.first) and return

    else
      redirect_to profile_url and return
    end
  end
  
  private
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      Time.zone = @property.setting.time_zone
    end
end