object @property

node do |n|
  hash = {
    :region => n.region ? n.region.name : nil,
    :name_url => link_to(n.name, property_path(n)),
    :show_path => property_path(n),
    :info_path => info_property_path(n),
    :edit_path => edit_property_path(n)
  }
  
  hash
end

attributes *Property.column_names
