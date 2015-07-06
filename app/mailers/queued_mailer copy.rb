class QueuedMailer
  #extend Resque::Plugins::Retry
  #@retry_limit = RETRY_LIMIT
  #@retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_medium
  end
  
  def self.unsubscribe_user_if_blacklisted(user, &f)
    begin
      
      msg = yield(f)

    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      pp ">>> Mailer Exception:", error_details
      
      user.unsubscribe("unsubscribe_blacklisted") if e.message.downcase.include?("blacklisted")
    end
  end
  
  def self.unsubscribe_entry_if_blacklisted(entry, campaign, &f)
    begin
      #TODO_ check if SES is off
      start_at = Time.now.to_f
      
      msg = yield(f)

      return { 
        :mimepart => (msg.content_type.scan(/_mimepart_\S*/).first.gsub('";', '') rescue nil),
        :executed_time => Time.now.to_f - start_at,
        :message_id => msg.message_id
      }

    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      pp ">>> Mailer Exception:", error_details
      
      if e.message.downcase.include?("blacklisted")
        resident.unsubscribe(campaign, "unsubscribe_blacklisted")
        
        return { :blacklisted => true }
      else
        return {}
      end
      
    end
  end
  
end
