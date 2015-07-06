class AudiencesController < ApplicationController
  
  include UserActivityHelper::Controller

  before_action :require_user
  before_action :set_property
  before_action :get_audience, :except => [:index, :new, :create, :leads, :size, :prop_list]
  
  @@per_page = 10

  def size
    if params[:ids]
      @audiences = @property.all_audiences.where(:id => params[:ids])
      
      res = @audiences.collect{|a| {:id => a.id.to_s, :count => a.residents_count} } #for json
      
    elsif params[:all]
      res = {:audiences => []}
      audiences = @property.all_audiences.where(:id => params[:all])
      
      if params[:detail]
        audiences.each do |a|
          res[:audiences] << {:id => a.id.to_s, :count => a.residents.count}
        end
      end
      
      if audiences.length == 1
        res[:total] = audiences.first.residents.count
      else
        res[:total] = Audience.unique_leads_count( @property.residents.or( audiences.collect{|a| a.residents.selector } ).selector ) #for json
      end
      
    elsif params[:aid]
      
      res = {:count => @property.all_audiences.find(params[:aid]).residents_count } #for json
    end
    
    respond_to do |format|
      format.js
      format.json {
        render :json => res
      }
    end
  end

  def leads
    
    @columns = @property.lead_def.to_columns("org_fields_first_name", [], @property.property? ? "sub_org" : "org")

    if !params[:all].blank?
      
      params[:all] = params[:all].split(",") if params[:all].kind_of?(String)
      
      # incorrect way
      # @residents = @property.residents.or( @property.all_audiences.where(:id => params[:all]).collect{|a| a.residents.selector } )
      # @residents = @residents.paginate(:page => params[:page], :per_page => params[:rp] || 10)
      
      selector = @property.residents.or( @property.all_audiences.where(:id => params[:all]).collect{|a| a.residents.selector } ).selector
      page = (params[:page] || 1).to_i
      per_page = (params[:rp] || 10).to_i
      limit = page*per_page
      skip = limit - per_page
      
      list = Audience.unique_leads_listing( selector, limit, skip)
      @total_residents = Audience.unique_leads_count( selector )
      
      @residents = @property.residents.where(:_id.in => list.collect{|l| l["_id"] })
      
    else
      if !params[:aid].blank?
        @audience = @property.all_audiences.find(params[:aid])
      
      else
        @audience = UserDefinedAudience.new(:property_id => @property.id, :expression => params[:expression])
      end
    
      @residents = @audience.residents.paginate(:page => params[:page], :per_page => params[:rp] || 10)
      
      @total_residents = @residents.total_residents
    end
    
    @residents.each{|e| e.curr_property_id = @property.id.to_s } if @property.property?
    
    @rows = {
      :rows=> @residents.collect{|e| {
        :id=> e.id.to_s, 
        :cell =>  sanitize_grid_cell(e.to_row(@columns, e.attributes, @property.property? ? "sub_org" : "org"))
      }},
      :page => params[:page] || 1,
      :total=> @total_residents # @total_residents is used in the view
    }

    respond_to do |format|
      format.js
      format.json {
        render :json => @rows
      }
    end
    
  end
  
  protected
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
    end
    
    def get_audience
      @audience = @property.audiences.find(params[:id])
    end
    
end
