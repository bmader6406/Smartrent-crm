object @user

node do |n|
  # @property is always an org_group
  role = n.roles.detect{|r| r if r.resource_id.nil? && r.resource_type == "Property" } #always exist
  property_roles = n.roles.collect{|r| r if r.resource_id && r.resource_type == "Property" }.compact
  region_roles = n.roles.collect{|r| r if r.resource_id && r.resource_type == "Region" }.compact
  
  hash = {
    :id => n.id.to_s,
    :name_url => link_to(n.full_name, user_path(n)),
    :full_name => n.full_name,
    :first_name => n.first_name,
    :last_name => n.last_name,
    :email => n.email,
    :role => role.name,
    :role_name => role.pretty_name,
    :authorized_property_ids => property_roles.collect{|r| r.resource_id.to_s }.compact,
    :authorized_region_ids => region_roles.collect{|r| r.resource_id.to_s }.compact,
    :show_path => user_path(n),
    :edit_path => edit_user_path(n)
  }
  
  if hash[:role] == "admin"
    hash[:authorized_properties] = "All Properties"
    
  elsif hash[:role] == "regional_manager"
    hash[:authorized_properties] = region_roles.collect{|r| r.resource.name }.compact.join(", ")
    
  else
    hash[:authorized_properties] = property_roles.length == Property.count ? "All Properties" : property_roles.collect{|r| r.resource.name if r.resource }.compact.join(", ")
  end
  
  hash
end

attributes :created_at
