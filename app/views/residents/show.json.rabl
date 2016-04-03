object @resident

# backgrid requires the unique :id
node do |n|
  if @property # property view, resident use the residentID_unitID format
    attrs = {
      :id => n.to_param,
      :show_path => property_resident_path(@property, n),
      :edit_path => edit_property_resident_path(@property, n),
      :tickets_path => tickets_property_resident_path(@property, n),
      :roommates_path => roommates_property_resident_path(@property, n),
      :units_path => units_property_resident_path(@property, n),
      :marketing_units_path => marketing_units_property_resident_path(@property, n),
      :activities_path => property_resident_activities_path(@property, n),
      :smartrent_path => smartrent_property_resident_path(@property, n),
      :add_ticket_path => property_resident_path(@property, n, :anchor => 'addTicket'),
      :property_name => @property.name
    }
  else #org group view (no conversation, no smartrent..., it shows only the resident units listing)
    attrs = {
      :id => n.to_param,
      :show_path => resident_path(n),
      :units_path => units_resident_path(n),
      :tickets_path => tickets_resident_path(n),
      :property_name => (@property_dict[n.property_id].name rescue "Deleted Property")
    }
  end
  
  # core fields
  [Resident::CORE_FIELDS, :created_at].flatten.each do |f|
    attrs[f] = n.send(f) || nil
  end
  attrs[:unit_code] = n.unit_code rescue ""
  attrs[:name] = n.full_name.blank? ? "N/A" : n.full_name
  
  if !n.nick_name.blank?
    attrs[:name] = "#{attrs[:name]} (#{n.nick_name})"
  end
  
  attrs[:birthday] = n.birthday.strftime("%m/%d/%Y") rescue nil
  attrs[:roommate_text] = ""
  
  if n.status == "Past"
    if n.unit_code.present?
      attrs[:unit_text] = "Past Resident ##{n.unit_code}"
      
    else
      attrs[:unit_text] = "Past Resident"
    end
    
  elsif n.status == "Future"
    if n.unit_code.present?
      attrs[:unit_text] = "Future Resident ##{n.unit_code}"
      
    else
      attrs[:unit_text] = "Future Resident"
    end
    
  else
    attrs[:unit_text] = "Unit ##{n.unit_code}"
  end
  
  if n.curr_unit
    attrs[:move_in] = n.curr_unit.move_in.strftime("%m/%d/%Y") rescue nil
    attrs[:status] = n.curr_unit.status
    
    if @property
      attrs[:roommate_text] = n.curr_unit.roommate? ? "Yes" : "No"
    end
  end
  
  # Mark as smartrent resident, load the rewards detail when the user view the resident detail
  attrs[:smartrent] = n.smartrent_resident ? true : false
  
  attrs
end

# unit fields
child :curr_unit => :unit do |u|
  [Resident::UNIT_FIELDS, :created_at].flatten.each do |f|
    node(f){|n| u.send(f) || nil }
  end
  
  node(:signing_date){|u| u.signing_date.strftime("%m/%d/%Y") rescue nil }
  node(:move_in){|u| u.move_in.strftime("%m/%d/%Y") rescue nil }
  node(:move_out){|u| u.move_out.strftime("%m/%d/%Y") rescue nil }
end
