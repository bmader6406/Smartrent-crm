object @property

node do |n|
  hash = {
    :region => n.region ? n.region.name : nil,
    :name_url => link_to(n.name, property_path(n), :class => "page-reload"),
    :show_path => property_path(n),
    :info_path => info_property_path(n),
    :edit_path => edit_property_path(n),
    :date_opened => (n.date_opened.strftime("%m/%d/%Y") rescue nil),
    :date_closed => (n.date_closed.strftime("%m/%d/%Y") rescue nil),
    :promotion_expiration_date => (n.promotion_expiration_date.strftime("%m/%d/%Y") rescue nil)
  }
  
  hash
end

attributes *Property.column_names
