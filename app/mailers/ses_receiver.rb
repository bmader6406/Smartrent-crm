class SesReceiver
  
  def self.queue
    :crm_medium
  end
  
  def self.perform(action, params)
    if action == "sns"
      
      bounces_count = 0
      bounces = []

      complaints_count = 0
      complaints = []

      message = JSON.parse(params["request_body"]["Message"]) rescue {}
      
      return true if message.empty?
      
      send_event = SendEvent.find_by_message_id("#{message["mail"]["messageId"]}@email.amazonses.com") rescue nil
      
      if send_event
        
        if message["notificationType"] == "Complaint"
          if !ComplaintEvent.where(:campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id).first
            ComplaintEvent.create( :property_id => send_event.property_id, :campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id )
          end
        
          complaints_count += 1
          complaints << "#{send_event.id}___#{ message["complaint"]["complainedRecipients"].collect{|b| b["emailAddress"]}.join(",") }"
        end
        
        ####
        
        if message["notificationType"] == "Bounce"
          if !BounceEvent.where(:campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id).first
            BounceEvent.create( :property_id => send_event.property_id, :campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id, :bounce_type => message["bounce"]["bounceType"] )
          end
        
          bounces_count += 1
          bounces << "#{send_event.id}___#{ message["bounce"]["bouncedRecipients"].collect{|b| b["emailAddress"]}.join(",") }"
        end
        
      end
      
      if bounces_count + complaints_count > 0
        MonitorMetric.create(:bounces_count => bounces_count, :bounces => bounces, :complaints_count => complaints_count, :complaints => complaints,
          :errors_count => 0, :error_details => [], :total => 1, :source => "sns")
      end
      
    else
      Resque.enqueue_to("crm_ses_not_found", action, params)
      
    end    
  end
  
end
