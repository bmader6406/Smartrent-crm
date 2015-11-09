class EmailConversationMailer
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(email_id)
    email = Email.find(email_id)
    comment = email.comment
    property = comment.property
    message = email.message.clone 

    if !email.is_reply?
      template = ::Template.find_by(property_id: property.id) rescue nil
      message = template.campaign.body_html.gsub("{%body_text%}", message) if template
      message = message.gsub("{%reply_callout%}", '<div style="color:#999; font-size:12px;font-family: arial;" class="reply-callout"><br> &nbsp; Please write ABOVE THIS LINE to reply <br><br></div>')
      message = message.gsub("{%view_unsubscribe_links%}", "")
    end
    
    Notifier.email_conversation(email.subject, message, email.to, {"from" => email.from, "reply_to" => email.reply_to, "cc" => email.cc}).deliver_now
  end

end
