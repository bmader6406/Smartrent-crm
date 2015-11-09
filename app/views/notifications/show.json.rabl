object @notification

node do |n|
  {
    :id => n.id.to_s,
    :show_path => property_resident_path(n.property_id, n.resident_unit_id), #TODO: highlight comment on resident page (:comment_id => n.comment_id)
    :state => n.state.titleize,
    :subject => n.subject,
    :message => strip_tags(n.message.to_s.gsub(/<br>|<br\/>|&nbsp;/," ")),
    :property_name => (n.property.name rescue nil),
    :unit_code => (n.unit.code rescue nil),
    :resident_name => (n.resident.full_name rescue nil),
    :created_time => n.created_at.strftime("%m/%d/%Y %l:%M %p"),
    :created_at => n.created_at.iso8601
  }
end