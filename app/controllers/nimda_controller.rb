require 'net/ftp'

class NimdaController < ApplicationController
  before_action :require_ssl

  http_basic_authenticate_with :name => NIMDA_U, :password => NIMDA_P
  
  layout "nimda"
  
  def show
    redirect_to nimda_templates_url
  end
  
  def units
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
    Resque.enqueue(UnitLoader, Time.now, params[:ftp_setting], params[:recipient])
    
    render :json => {:success => true}
  end
  
  def yardi
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
    Resque.enqueue(YardiLoader, Time.now, params[:ftp_setting], params[:recipient])
    
    render :json => {:success => true}
  end
  
end
