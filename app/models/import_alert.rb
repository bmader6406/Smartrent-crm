class ImportAlert < ActiveRecord::Base
  
  validates :property_id, :unit_code, :tenant_code, :email, :presence => true
  
  belongs_to :actor, :class_name => "User"
  belongs_to :property
  
  after_update :update_notification
  
  def message
    return <<-MESSAGE
Yardi is showing that Unit <b>#{unit_code}</b> does not have the Resident <b>#{tenant_code}</b> with email <b>#{email}</b> anymore. 
If the resident has moved out of the unit, please remove the resident from the CRM manually.
If this resident has not moved out, please make sure this resident is assigned to the unit in Yardi.
    MESSAGE
  end
  
  private
    
    def update_notification
      if acknowledged_changed? && acknowledged
        n = property.notifications.find_by_import_alert_id(id)
        
        if n && !n.acknowledged?
          n.last_actor = actor
          n.state = "acknowledged"
          n.save
        end
      end
    end
  
end
