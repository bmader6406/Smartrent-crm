object @ticket

node do |n|
  {
    :id => n.id.to_s,
    :id_url => link_to(n.id, "#{tickets_property_resident_path(@property, n.resident_id)}/#{n.id}"),
    :resident_id => n.resident_id.to_s,
    :resident_url => link_to(n.resident_id, tickets_property_resident_path(@property, n.resident_id)),
    :status => n.status,
    :first_name => n.resident.first_name,
    :created_date => n.created_at.strftime('%m/%d/%Y'),
    :category => n.category.name,
    :category_id => n.category_id.to_s,
    :show_path => "#{tickets_property_resident_path(@property, n.resident_id)}/#{n.id}",
    
    :assigner => {
      :full_name => n.assigner.full_name,
      :email => n.assigner.email
    },
    :assigner_id => n.assigner_id.to_s,
    
    :assignee => {
      :full_name => n.assignee.full_name,
      :email => n.assignee.email
    },
    :assignee_id => n.assignee_id.to_s,
    :can_enter => n.can_enter ? 1 : 0,
    :assets => n.assets.collect{ |a| a.to_jq_upload }
  }
end

node(:property, :if => lambda {|n| n.property }) do |n|
  {
    :name => n.property.name,
    :id => n.property.id.to_s
  }
end

attributes :created_at, :title, :description, :urgency, :entry_instruction, :additional_emails, :additional_phones
