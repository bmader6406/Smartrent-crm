object @activity

node do |n|
  {
    :id => n.id.to_s,
    :action => n.action,
    :created_at => n.created_at.iso8601
  }
end

node(:marketing, :if => lambda {|n| n.kind_of?(MarketingActivity) }) do |n|
  {
    :note => n.note
  }
end

node(:author, :if => lambda {|n| n.subject.has_author? rescue false }) do |n|
  comment = n.subject
  {
    :full_name => comment.author.full_name,
    :email => comment.author.email,
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
    :recording_url => comment.call.recording_url,
    :update_path => update_note_property_resident_activity_path(n.property_id, @resident.id, n.id)
  }
end

node(:email, :if => lambda {|n| n.subject.email rescue false }) do |n|
  comment = n.subject
  {
    :from => comment.email.from,
    :is_received => comment.author.kind_of?(Resident),
    :to => comment.email.to,
    :subject => comment.email.subject,
    :message => comment.email.message
  }
end


node(:notification) do |n|
  notification = n.subject.kind_of?(Comment) && n.subject.email? ? n.subject.notification : nil
  hash = {}
  
  if notification
    hash = {
      :state => notification.state,
      :acknowledge_path => acknowledge_property_resident_activity_path(n.property_id, @resident.id, n.id),
      :reply_path => reply_property_resident_activity_path(n.property_id, @resident.id, n.id),
      :histories => []
    }

    if notification.owner
      hash[:owner] = {
        :id => notification.owner.id.to_s,
        :full_name => notification.owner.full_name,
        :email => notification.owner.email
      }
    end
    
    if notification.last_actor
      hash[:last_actor] = {
        :id => notification.last_actor.id.to_s,
        :full_name => notification.last_actor.full_name,
        :email => notification.last_actor.email
      }
    end
    
    notification.histories.sort{|a, b| b.created_at <=> a.created_at }.each do |h|
      hash[:histories] << {
        :full_name => h.actor ? h.actor.full_name : "Deleted User ##{h.actor_id}",
        :email => h.actor ? h.actor.email : "Deleted User ##{h.actor_id}",
        :state => h.state,
        :pretty_state => h.state.titleize,
        :created_time => h.created_at.strftime("%m/%d/%Y %l:%M %p")
      }
    end
  end
  
  hash
end

node(:note, :if => lambda {|n| n.subject.note? rescue false }) do |n|
  comment = n.subject
  {
    :message => comment.message,
    :update_path => update_note_property_resident_activity_path(n.property_id, @resident.id, n.id)
  }
end

node(:document, :if => lambda {|n| (n.subject.document? && !n.subject.assets.empty?) rescue false }) do |n|
  comment = n.subject
  {
    :message => comment.message,
    :assets => comment.assets.collect{ |a| a.to_jq_upload }
  }
end

node(:ticket, :if => lambda {|n| n.subject.kind_of?(Ticket) }) do |n|
  ticket = n.subject
  hash = {
    :activity_author => nil,
    :ticket_path => tickets_property_resident_path(ticket.property_id, ticket.resident_id, :anchor => ticket.id),
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
