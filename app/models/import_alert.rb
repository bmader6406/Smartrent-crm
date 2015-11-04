class ImportAlert < ActiveRecord::Base
  
  validates :property_id, :unit_code, :tenant_code, :email, :presence => true
  
  belongs_to :actor, :class_name => "User"
  
  def message
    return <<-MESSAGE
Yardi is showing that Unit <b>#{unit_code}</b> does not have the Resident <b>#{tenant_code}</b> with email <b>#{email}</b> anymore. 
If the resident has moved out of the unit, please remove the resident from the CRM manually.
If this resident has not moved out, please make sure this resident is assigned to the unit in Yardi.
    MESSAGE
  end
  
end
