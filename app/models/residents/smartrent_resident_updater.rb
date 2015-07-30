require 'csv'

class SmartrentResidentUpdater
  def self.queue
    :crm_immediate
  end
  
  def self.perform(resident_id, prop_id)
    resident = Resident.find(resident_id)
    prop = resident.properties.find(prop_id)

    sr = Smartrent::Resident.find_or_initialize_by(crm_resident_id: resident._id)
    sr.email = resident.email
    sr.smartrent_status = Smartrent::Resident.SMARTRENT_STATUS_ACTIVE if sr.smartrent_status.blank?
    sr.save(:validate => false)
  
    sr_property = sr.resident_properties.find_or_initialize_by(property_id: prop.property_id)
    sr_property.status = prop.status
    sr_property.move_in_date = prop.move_in
    sr_property.save
  end
  
end