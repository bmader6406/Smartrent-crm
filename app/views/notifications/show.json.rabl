object @notification

node do |n|
  {
    :id => n.id.to_s,
    :show_path => property_notification_path(@property, n),
    :edit_path => edit_property_notification_path(@property, n)
  }
end

attributes :created_at
