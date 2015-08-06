class ResidentPasswordsController < ApplicationController
  before_filter :require_user
  before_filter :set_resident

  def reset
    @smartrent_resident.send_reset_password_instructions
    @smartrent_resident.update_attribute(:confirmed_at, Time.now) if !@smartrent_resident.confirmed_at
    
    render :json => {:success => true}
  end

  def update
    if @smartrent_resident.update_attributes(resident_params)
      @smartrent_resident.update_attribute(:confirmed_at, Time.now) if !@smartrent_resident.confirmed_at
      
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end
  
  def set_status
    if @smartrent_resident.update_changable_smartrent_status(params[:smartrent_status])
      render :json => {:success => true}
    else
      render :json => {:success => false}
    end
  end

  def become_champion
    if @smartrent_resident.become_champion(params[:amount])
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
