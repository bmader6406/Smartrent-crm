object @resident

node do |n|
  attrs = {
    :id => n.id.to_s,
    :name_url => link_to(n.full_name, property_resident_path(@property, n)),
    :show_path => property_resident_path(@property, n),
    :edit_path => edit_property_resident_path(@property, n),
    :tickets_path => tickets_property_resident_path(@property, n),
    :roommates_path => roommates_property_resident_path(@property, n),
    :properties_path => properties_property_resident_path(@property, n),
    :marketing_properties_path => marketing_properties_property_resident_path(@property, n),
    :activities_path => resident_property_activities_path(@property, n)
  }
  
  # core fields
  [Resident::CORE_FIELDS, :created_at].flatten.each do |f|
    attrs[f] = n.send(f) || nil
  end
  
  attrs[:birthday] = n.birthday.strftime("%m/%d/%Y") rescue nil
  
  attrs
end

# property fields
child :curr_property => :property do |p|
  [Resident::PROPERTY_FIELDS, :created_at].flatten.each do |f|
    node(f){|n| p.send(f) || nil }
  end
  
  node(:signing_date){|p| p.signing_date.strftime("%m/%d/%Y") rescue nil }
  node(:move_in){|p| p.move_in.strftime("%m/%d/%Y") rescue nil }
  node(:move_out){|p| p.move_out.strftime("%m/%d/%Y") rescue nil }
end