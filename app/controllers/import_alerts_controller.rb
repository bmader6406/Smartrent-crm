class ImportAlertsController < ApplicationController
  before_action :require_user
  before_action :set_property
  before_action :set_page_title
  
  def index
    respond_to do |format|
      format.html {
        @new_alerts = @property.import_alerts.order('created_at desc').where(:acknowledged => false).paginate(:page => params[:page], :per_page => 15)
        @acknowledged_alerts = @property.import_alerts.order('acknowledged_at desc').where(:acknowledged => true).paginate(:page => params[:page], :per_page => 15)
      }
      format.js {
        @alerts = @property.import_alerts.order(params[:acknowledged] == "1" ? 'acknowledged_at desc' : 'created_at desc')
          .where(:acknowledged => params[:acknowledged]).paginate(:page => params[:page], :per_page => 15)
      }
    end
  end
  
  def show
    @alert = @property.import_alerts.find(params[:id])
    pp "@alert", @alert
    index
    render :action => :index
  end
  
  def acknowledge
    import_alert = @property.import_alerts.find(params[:id])
    import_alert.acknowledged = true
    import_alert.acknowledged_at = Time.now
    import_alert.actor = current_user
    
    if import_alert.save
      render :json => {:success => true}
      
    else
      render :json => {:success => false, :error => errors.full_messages }
    end
  end
  
  private
  
    def unit_params
      params.require(:unit).permit!
    end
    
    def set_property
      @property = current_user.managed_properties.find(params[:property_id])
      authorize! :read, @property
      Time.zone = @property.setting.time_zone
    end
    
    def set_page_title
      @page_title = "CRM - #{@property.name} - Data Import Alerts" 
    end
  
end
