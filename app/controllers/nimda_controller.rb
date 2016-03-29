require 'net/ftp'

class NimdaController < ApplicationController
  before_action :require_user
  before_action :require_admin
  before_action :set_page_title
  
  layout "application"
  
  def show
    redirect_to nimda_templates_url
  end
  
  def units
    @import = Import.find_or_initialize_by(type: "load_units_one_time")
    @import.save if @import.new_record?
    
    @daily_import = Import.find_or_initialize_by(type: "load_units_weekly")
    @daily_import.save if @daily_import.new_record?
  end
  
  def load_units
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting])
    
    if params[:active]
      import.update_attributes(:active => params[:active])
    else
      Resque.enqueue(UnitLoader, Time.now, import.id)
    end
    
    render :json => {:success => true}
  end
  
  def yardi
    @import = Import.find_or_initialize_by(type: "load_yardi_one_time")
    @import.save if @import.new_record?
    
    @daily_import = Import.find_or_initialize_by(type: "load_yardi_daily")
    @daily_import.save if @daily_import.new_record?
  end
  
  def load_yardi
    import = Import.find_by_type(params[:type])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map])
    
    if params[:active]
      import.update_attributes(:active => params[:active])
    else
      Resque.enqueue(YardiLoader, Time.now, import.id)
    end
    
    render :json => {:success => true}
  end
  
  def non_yardi
    @imports = Import.where(type: "load_non_yardi_daily").all # it is supposed to run weekly but we check for the feed daily, run the import if any
    
    if @imports.empty?
      import = Import.find_or_initialize_by(type: "load_non_yardi_daily")
      import.save if import.new_record?
      
      @imports = [import]
    end
  end
  
  def create_non_yardi
    Import.create(type: "load_non_yardi_daily")
    
    render :json => {:success => true}
  end
  
  def delete_non_yardi
    Import.find(params[:id]).update_attribute(:deleted_at, Time.now)
    
    render :json => {:success => true}
  end
  
  def load_non_yardi
    import = Import.find(params[:id])
    import.update_attributes(:ftp_setting => params[:ftp_setting], :field_map => params[:field_map], :property_map => params[:property_map])
    
    if params[:active]
      import.update_attributes(:active => params[:active])
    end
    
    render :json => {:success => true}
  end
  
  
  def test_ftp
    begin
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect(params[:ftp_setting][:host])
      ftp.login(params[:ftp_setting][:username], params[:ftp_setting][:password])
      ftp.close
    
      render :json => {:success => true}
      
    rescue Exception => e
      pp "ftp test ERROR: ", e
      
      render :json => {:success => false}
    end
  end
  
  
  protected
  
    def set_page_title
      Time.zone = "Eastern Time (US & Canada)" #temp
      
      @page_title = "CRM - Admin"
    end
  
end
