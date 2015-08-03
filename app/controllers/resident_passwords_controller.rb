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
    if @smartrent_resident.update_attributes({:smartrent_status => params[:smartrent_status].capitalize})
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end
  
  def set_amount
    if @smartrent_resident.rewards.find(params[:reward_id]).update_attributes(:amount => params[:amount])
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end
  
  private
    def resident_params
      params.require(:resident).permit!
    end
    
    def set_resident
      @smartrent_resident = current_user.managed_residents.find(params[:id])
    end
    
end
