class ImportAlert < ActiveRecord::Base
  
  validates :property_id, :unit_code, :tenant_code, :email, :presence => true
  
  belongs_to :actor, :class_name => "User"
  
  def message
    return <<-MESSAGE
Yardi is showing that Unit <b>#{unit_code}</b> does not have the Resident <b>#{tenant_code}</b> with email <b>#{email}</b> anymore. 
If valid, please reflect these changes in the CRM. If this is not a valid change, 
please make sure Yardi contains the correct resident for this unit.
    MESSAGE
  end
  
end
