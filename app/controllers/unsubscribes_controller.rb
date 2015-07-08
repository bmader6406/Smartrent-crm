class UnsubscribesController < ApplicationController
  before_action :set_page_title
  
  def index
    render :text => "Page Not Found"
  end
  
  def show
    if params[:id] == "123456" #test resident

    elsif params[:id].include?("u_") #user
      @user = User.find_by_id(params[:id][2..-11])
      
      render :action => "confirm" and return if !@user.subscribed?
        
    elsif params[:id] #entry
      @resident = Resident.find_by_id(params[:id][0..-11])
      
      @campaign = Campaign.find(params[:cid])
      
      if !@resident
        render :text => "Entry Not Found" and return
      end
      
      switch_page
      
      render :action => "confirm" and return if !@resident.subscribed?(@property)
    end
    
  end
  
  def confirm
    if params[:id] == "123456" #test resident

    elsif params[:id].include?("u_") #user
      @user = User.find_by_id(params[:id][2..-11])
      
      if @user
        @user.unsubscribe("unsubscribe_confirm")
        
      else
        render :text => "User Not Found"
      end
      
    elsif params[:id] #entry
      @resident = Resident.find_by_id(params[:id][0..-11])
  
      if @resident
        @campaign = Campaign.find(params[:cid])
        
        switch_page
        
        @resident.unsubscribe(@campaign, params[:all] ? "unsubscribe_confirm_all" : "unsubscribe_confirm")
          
        event = UnsubscribeClickEvent.find_by(campaign_id: @campaign.id, resident_id: @resident.id)
      
        if !event
          UnsubscribeClickEvent.create( :property_id => @campaign.property_id, :campaign_id => @campaign.id, :resident_id => @resident.id )
        end
      
      else
        render :text => "Entry Not Found"
      end
      
    else
      render :text => "Page Not Found", :layout => false
    end

  end
  
  def subscribe
    @properties = Property.where(:id => params[:property_id]).order("name asc") if params[:property_id]
    
    if params[:id] == "123456" #test entry

    elsif params[:id].include?("u_") #user
      @user = User.find_by_id(params[:id][2..-11])
      
      if @user
        @user.subscribe
        
      else
        render :text => "User Not Found"
      end
      
    elsif params[:id] #entry
      @resident = Resident.find_by_id(params[:id][0..-11])
      
      @campaign = Campaign.find(params[:cid])
      
      switch_page
      
      @properties = [@property] if !@properties
      
      if @resident
        @resident.subscribe(@campaign, @properties)

      else
        render :text => "Entry Not Found"
      end
      
    else
      render :text => "Page Not Found"
    end
  end
  
  protected
  
    def set_page_title
      @page_title = "CRM - Unsubscribe"
    end
    
    def switch_page #if the lead not belongs to this page, switch to the shared audience page
      @property = @campaign.property
      
      if !@resident.properties.detect{|p| p.property_id == @property.id.to_s }
        audience = @resident.to_cross_audience(@campaign)
        
        if audience && audience.property
          @property = audience.property
          @campaign.tmp_property_id = @property.id
          #pp ">>> page switch #{@campaign.tmp_property_id} #{@property.name}"
        end
      end
      
    end
  
    
end
