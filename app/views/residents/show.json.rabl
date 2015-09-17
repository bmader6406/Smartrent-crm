object @resident

node do |n|
  attrs = {
    :id => n.id.to_s
  }
  
  if @property
    attrs.merge!({
      :name_url => link_to(n.full_name.blank? ? "N/A" : n.full_name, property_resident_path(@property, n)),
      :show_path => property_resident_path(@property, n),
      :edit_path => edit_property_resident_path(@property, n),
      :tickets_path => tickets_property_resident_path(@property, n),
      :roommates_path => roommates_property_resident_path(@property, n),
      :properties_path => properties_property_resident_path(@property, n),
      :marketing_properties_path => marketing_properties_property_resident_path(@property, n),
      :activities_path => property_resident_activities_path(@property, n),
      :smartrent_path => smartrent_property_resident_path(@property, n)
    })
  else
    attrs.merge!({
      :name_url => link_to(n.full_name.blank? ? "N/A" : n.full_name, resident_path(n)),
      :show_path => resident_path(n),
      :edit_path => edit_resident_path(n),
      :tickets_path => tickets_resident_path(n),
      :roommates_path => roommates_resident_path(n),
      :properties_path => properties_resident_path(n),
      :marketing_properties_path => marketing_properties_resident_path(n),
      :activities_path => resident_activities_path(n)
    })
  end
  
  # core fields
  [Resident::CORE_FIELDS, :created_at].flatten.each do |f|
    attrs[f] = n.send(f) || nil
  end
  
  attrs[:birthday] = n.birthday.strftime("%m/%d/%Y") rescue nil
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
  
  if n.curr_property
    attrs[:move_in] = n.curr_property.move_in.strftime("%m/%d/%Y") rescue nil
    attrs[:status] = n.curr_property.status
  end
  
  # Mark as smartrent resident, load the rewards detail when the user view the resident detail
  attrs[:smartrent] = n.smartrent_resident ? true : false
  
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

# This generate a lot of rewards query
# child :smartrent_resident => :smartrent do |sr|
#   node do |n|
#     {
#       :total_rewards => number_to_currency(sr.total_rewards, :precision => 0),
#       :monthly_awards_amount => number_to_currency(sr.monthly_awards_amount, :precision => 0),
#       :sign_up_bonus => number_to_currency(sr.sign_up_bonus, :precision => 0),
#       :initial_reward => number_to_currency(sr.initial_reward, :precision => 0)
#     }
#   end
# end
