object @campaign

node do |n|
  hash = {
    :id => n.id.to_s,
    :id_url => link_to(n.subject, edit_property_campaign_path(@property, n)),
    :show_path => property_campaign_path(@property, n),
    :edit_path => edit_property_campaign_path(@property, n),
    :subject => n.subject,
    :from => n.from,
    :audience_id => n.audience_ids.first,
    :audience_name => n.audiences.collect{|a| a.name },
    :body_text => n.body_text,
    :published_at => (n.published_at.to_s(:friendly_time) rescue nil),
    :published_date => (n.published_at.strftime("%Y-%b-%d") rescue nil),
    :published_time => (n.published_at.strftime("%l:%M %p") rescue nil)
  }
  
  arr = [link_to("Preview", preview_property_campaign_path(@property, n), :target => "_blank")]
  
  if n.sends_count > 0
    arr << link_to("Report", property_campaign_reports_path(@property, n), :target => "_blank")
  end
  
  hash[:actions] = arr.join(" | ")
  
  hash
end

attributes :subject, :created_at