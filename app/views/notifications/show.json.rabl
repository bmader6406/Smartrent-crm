object @notification

node do |n|
  attrs = {
    :id => n.id.to_s,
    :state => n.state.titleize,
    :subject => n.subject,
    :message => strip_tags(n.message.to_s.gsub(/<br>|<br\/>|&nbsp;/," ")),
    :property_name => (n.property.name rescue nil),
    :unit_code => (n.unit.code rescue nil),
    :resident_name => (n.resident.full_name rescue nil),
    :import_alert_id => n.import_alert_id,
    :created_time => n.created_at.strftime("%m/%d/%Y %l:%M %p"),
    :created_at => n.created_at.iso8601
  }
  
  if n.import_alert_id
    attrs[:show_path] = property_import_alert_path(n.property_id, n.import_alert_id, :notif => 1)
    
  else
    attrs[:show_path] = property_resident_path(n.property_id, n.resident_unit_id, :notif => 1)
  end
  
  attrs
end