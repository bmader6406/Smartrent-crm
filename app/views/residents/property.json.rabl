object @property

node do |n|
  prop = n.property
  {
    :id => n.id.to_s,
    :name => prop.name,
    :resident_path => property_resident_path(prop, @resident),
    :created_at => n.created_at.iso8601,
    :status_date => (n.status_date.strftime("%m/%d/%Y") rescue nil), 
    :signing_date => (n.signing_date.strftime("%m/%d/%Y") rescue nil), 
    :move_in => (n.move_in.strftime("%m/%d/%Y") rescue nil), 
    :move_out => (n.move_out.strftime("%m/%d/%Y") rescue nil)
  }
end

attributes  :type, :status
