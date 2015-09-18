object @notification

node do |n|
  {
    :id => n.id.to_s,
    :state => n.state,
    :message => n.message,
    :created_at => n.created_at.iso8601,
    :updated_at => n.created_at.iso8601
  }
end

node(:property, :if => lambda {|n| n.property }) do |n|
  {
    :id => n.property.id,
    :name => n.property.name
  }
end

node(:resident, :if => lambda {|n| n.resident }) do |n|
  {
    :id => n.resident.id.to_s,
    :full_name => n.resident.full_name,
    :email => n.resident.email
  }
end

node(:owner, :if => lambda {|n| n.owner }) do |n|
  {
    :id => n.owner.id.to_s,
    :full_name => n.owner.full_name,
    :email => n.owner.email
  }
end

node(:last_actor, :if => lambda {|n| n.last_actor }) do |n|
  {
    :id => n.last_actor.id.to_s,
    :full_name => n.last_actor.full_name,
    :email => n.last_actor.email
  }
end