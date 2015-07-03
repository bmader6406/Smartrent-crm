object @property

node do |n|
  prop = n.property
  {
    :id => prop.id.to_s,
    :name => prop.name,
    :resident_path => resident_path(prop, @resident)
  }
end

attributes  :type, :status, :status_date, :signing_date, :move_in, :move_out, :created_at
