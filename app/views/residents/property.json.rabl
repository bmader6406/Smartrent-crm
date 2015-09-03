object @property

node do |n|
  prop = n.property
  {
    :id => prop.id.to_s,
    :name => prop.name,
    :resident_path => property_resident_path(prop, @resident),
    :created_at => n.created_at.iso8601
  }
end

attributes  :type, :status, :status_date, :signing_date, :move_in, :move_out
