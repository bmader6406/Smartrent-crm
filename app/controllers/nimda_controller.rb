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
  
  def test_units_ftp
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
  
  def test_yardi_ftp
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
  
  def import_alerts
    respond_to do |format|
      format.html {
        @new_alerts = ImportAlert.order('created_at desc').where(:acknowledged => false).paginate(:page => params[:page], :per_page => 15)
        @acknowledged_alerts = ImportAlert.order('acknowledged_at desc').where(:acknowledged => true).paginate(:page => params[:page], :per_page => 15)
      }
      format.js {
        @alerts = ImportAlert.order(params[:acknowledged] == "1" ? 'acknowledged_at desc' : 'created_at desc')
          .where(:acknowledged => params[:acknowledged]).paginate(:page => params[:page], :per_page => 15)
      }
    end
  end
  
  def acknowledge
    import_alert = ImportAlert.find(params[:id])
    import_alert.acknowledged = true
    import_alert.acknowledged_at = Time.now
    import_alert.actor = current_user
    
    if import_alert.save
      render :json => {:success => true}
      
    else
      render :json => {:success => false, :error => errors.full_messages }
    end
  end
  
  protected
  
    def set_page_title
      Time.zone = "Eastern Time (US & Canada)" #temp
      
      @page_title = "CRM - Admin"
    end
  
end
