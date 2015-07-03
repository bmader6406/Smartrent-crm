object @activity

node do |n|
  {
    :id => n.id.to_s,
    :action => n.action,
    :created_at => n.created_at
  }
end

node(:marketing, :if => lambda {|n| n.kind_of?(EntryActivity) }) do |n|
  {
    :note => n.note,
    :tour_time => n.action == "schedule" && n.target ? n.target.tour_time : nil
  }
end

node(:author, :if => lambda {|n| n.subject.has_author? rescue false }) do |n|
  comment = n.subject
  {
    :full_name => comment.author.full_name,
    :type => comment.author.class.to_s,
    :id => comment.author.id.to_s
  }
end

node(:call, :if => lambda {|n| n.subject.call rescue false }) do |n|
  comment = n.subject
  {
    :from => comment.call.from,
    :to => comment.call.to,
    :message => comment.message,
    :recording_duration => comment.call.recording_duration,
    :recording_url => comment.call.recording_url
  }
end

node(:email, :if => lambda {|n| n.subject.email rescue false }) do |n|
  comment = n.subject
  {
    :from => comment.email.from,
    :to => comment.email.to,
    :subject => comment.email.subject,
    :message => comment.email.message
  }
end

node(:note, :if => lambda {|n| n.subject.note? rescue false }) do |n|
  comment = n.subject
  {
    :message => comment.message
  }
end

node(:document, :if => lambda {|n| (n.subject.document? && !n.subject.assets.empty?) rescue false }) do |n|
  comment = n.subject
  pp comment
  {
    :message => comment.message,
    :assets => comment.assets.collect{ |a| a.to_jq_upload }
  }
end

node(:ticket, :if => lambda {|n| n.subject.kind_of?(Ticket) }) do |n|
  ticket = n.subject
  hash = {
    :activity_author => nil,
    :ticket_path => tickets_resident_path(ticket.property_id, ticket.resident_id, :anchor => ticket.id),
    :description => ticket.description,
    :assigner => {
      :full_name => ticket.assigner.full_name,
      :email => ticket.assigner.email
    },
    :assigner_id => ticket.assigner_id.to_s,
    :assignee => {
      :full_name => ticket.assignee.full_name,
      :email => ticket.assignee.email
    },
    :assignee_id => ticket.assignee_id.to_s
  }
  
  if n.author #hack
    hash[:activity_author] = {
      :full_name => n.author.full_name,
      :id => n.author.id.to_s
    }
  end
  
  hash
end
