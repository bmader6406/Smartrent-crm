object @property

node do |n|
  lead_source = {}
  {
    :id => n.property.id.to_s,
    :name => n.property.name,
    :subscribed => n.subscribed?,
    :status => n.status,
    :resident_status => n.resident_status,
    :lead_type => n[lead_source["lead_type"]],
    :lead_source => n[lead_source["lead_source"]],
    :created_at => n.created_at.strftime("%m/%d/%Y"),
    :sends_count => n.sends_count,
    :clicks_count => n.clicks_count,
    :statuses_path => marketing_statuses_property_resident_path(@property, @resident, :prop_id => n.property_id),
    :activities_path => resident_activities_path(n.property, @resident, :history => "marketing")
  }
end