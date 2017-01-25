# encoding: utf-8

class SesMonitor
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_medium
  end
  
  def self.perform
    
    bounces_count = 0
    bounces = []
    
    complaints_count = 0
    complaints = []
    
    errors_count = 0
    errors = []
    
    total = 0
    property_ids = Property.all.collect{|p| p.id }
    
    Mail.find_and_delete({:what => :last, :count => 150, :order => :desc}) { |m| 
      # don't delete any email
      #m.skip_deletion
      
      total += 1
      
      begin
        #next if !m.subject.to_s.include?("Delivery Status")
        from = m.from.first.to_s.gsub(/(.*<|>.*)/, '')
        subject = m.subject.to_s
        final_recipient = m.final_recipient.split(';').last.to_s.strip.gsub(/(.*<|>.*)/, '').gsub('rfc822;', '') rescue nil
        mimepart = nil
        send_event = !m.message_id.blank? ? SendEvent.find_by_message_id(m.message_id) : nil
        
        if !send_event
          mimepart = m.body.to_s.scan(/_mimepart_\S*/).first.gsub(/;|\"|=3D2=/i, '') rescue nil
          send_event = !mimepart.blank? ? SendEvent.find_by_mimepart(mimepart) : nil
        end
        
        pp "#{total}: from: #{from}, subject: #{subject}, final_recipient: #{final_recipient}, send_event: #{(send_event.id rescue nil)}, bounce? :#{m.bounced?}, m.message_id: #{m.message_id}, mimepart: #{mimepart}"
        #pp "m.body.to_s: #{m.body.to_s}"
        
        unsubscribed_user = false
        unsubscribed_lead = false
        
        if subject.include?("complaint") || from.include?("complaint") || from.include?("abuse") #complaint
          pp ".......COMPLAINT"
          if send_event
            
            if !ComplaintEvent.where(:campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id).first
              ComplaintEvent.create( :property_id => send_event.property_id, :campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id )
            end
                
            complaints_count += 1
            complaints << "#{send_event.id}___#{final_recipient}"
            
          else
            unsubscribed_lead = unsubscribe_resident(final_recipient, property_ids, "bad_email_found")
          end
        
          unsubscribed_user = unsubscribe_user(final_recipient, "unsubscribe_complaint")
          
        elsif m.bounced? && !subject.downcase.include?("delayed mail") || bounced_subject?(subject)
          pp ".......BOUNCE"
          if send_event
            
            if !BounceEvent.where(:campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id).first
              BounceEvent.create( :property_id => send_event.property_id, :campaign_id => send_event.campaign_id, :resident_id => send_event.resident_id )
            end
                            
            bounces_count += 1
            bounces << "#{send_event.id}___#{final_recipient}"
            
          else
            unsubscribed_lead = unsubscribe_resident(final_recipient, property_ids, "bad_email_found")
          end
          
          unsubscribed_user = unsubscribe_user(final_recipient, "unsubscribe_bounce")
          
        else
          pp ".......UNKNOWN: subject #{subject}"
          
        end
      
        pp ""
        pp ""
        
        if autoreply_subject?(subject) || unsubscribed_lead || unsubscribed_user
          # do nothing, the message will be deleted
          pp ">>> #{total}. deleted message: #{subject}"
          
        elsif !send_event
          m.skip_deletion
          
        end
        
      rescue Exception => e
        
        m.skip_deletion
        
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace

        p "ERROR: #{error_details}"
        
        errors_count += 1
        errors << "#{m.subject}___#{final_recipient}___#{error_details}"
      end
    }
    
    MonitorMetric.create(:bounces_count => bounces_count, :bounces => bounces, :complaints_count => complaints_count,:complaints => complaints,
      :errors_count => errors_count, :error_details => errors, :total => total)
  end
  
  # SesReceiver will not unsubscribe lead
  def self.unsubscribe_resident(email, property_ids, type)
    return true if Rails.env.stage?
    pp "unsubscribing lead..."
    unsubscribed = false
    
    if !email.blank?
      property_ids.each do |property_id|
        Resident.where(:email_lc => email).each do |e|
          pp "FOUND: #{e.email}, property_id: #{property_id}"
          e.marketing_activities.create(:action => "bad_email_found")
          e.update_attribute(:subscribed, false)
          e.units.update_all(:subscribed => false)
          
          unsubscribed = true if !unsubscribed
        end
      end
    end
    
    unsubscribed
  end
  
  # SesReceiver will not unsubscribe user
  def self.unsubscribe_user(email, type)
    return true if Rails.env.stage?
    pp "unsubscribing user..."
    unsubscribed = false
    
    if !email.blank?
      user = User.find_by_email(email)
      if user
        user.unsubscribe(type)
        unsubscribed = true
      end

    end
    
    unsubscribed
  end
  
  def self.autoreply_subject?(subject)
    [
      "autoreply", "autoresponse", "auto response", "automatic reply", "automatic response", "automated reply", "auto reply", "auto-reply",
      "automated response", "email address has changed", "autonotify",
      "out of office", "out of the office", "out of town", "out of the town", "out of country", "out of the country",
      "re:", "auto:", "warning:", "delayed mail", "away from my mail", "away from my email", "vacation"].any?{|w| subject.downcase.include?(w) }
  end
  
  def self.bounced_subject?(subject)
    [
      "delivery status notification (failure)",
      "undelivered mail", 
      "returned mail: over quota",
      "non-delivery",
      "delivery has failed",
      "possible mail loop",
      "undeliverable:",
      "delivery failure",
      "rejected:",
      "End of employment",
      "End of Tour",
      "failure notice"
    ].any?{|w| subject.downcase.include?(w) }
  end

end
