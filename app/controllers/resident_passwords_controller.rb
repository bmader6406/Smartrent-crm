class ResidentPasswordsController < ApplicationController
  before_filter :require_user
  before_filter :set_resident

  def reset
    @smartrent_resident.send_reset_password_instructions
    
    render :json => {:success => true}
  end

  def update
    
    if @smartrent_resident.update_attributes(resident_params)
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end
  
  def set_status
    #placeholder
    # TODO: Tala please write code for this method (I am waiting for the multiple properties backend change)
  end
  
  private
    def resident_params
      params.require(:resident).permit!
    end
    
    def set_resident
      #TODO: use current_user.managed_residents.find
      @smartrent_resident = Smartrent::Resident.find(params[:id])
    end
    
end
