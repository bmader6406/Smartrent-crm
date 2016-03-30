object @unit

node do |n|
  prop = n.property
  {
    :id => n.id.to_s,
    :name => prop.name,
    :show_path => property_resident_path(prop, "#{@resident.id}_#{n.unit_id}"),
    :created_at => n.created_at.iso8601,
    :status_date => (n.status_date.strftime("%m/%d/%Y") rescue nil), 
    :signing_date => (n.signing_date.strftime("%m/%d/%Y") rescue nil), 
    :move_in => (n.move_in.strftime("%m/%d/%Y") rescue nil), 
    :move_out => (n.move_out.strftime("%m/%d/%Y") rescue nil),
    :unit_code => n.unit_code,
    :unit_id => n.unit_id,
    :roommate => n.roommate?,
    :roommate_text => n.roommate? ? "Yes" : "No"
  }
end

attributes  :type, :status
