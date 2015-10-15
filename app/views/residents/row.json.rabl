object @resident

node do |r|
  # for some reason, node requires the return object to be a hash
  { 
    :row => [
      r.unit_code,
      r.full_name,
      r.email,
      link_to("Create Ticket", property_resident_path(@property, r, :anchor => "addTicket"))
    ] 
  }
end