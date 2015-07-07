class SpamishEmailScheduled
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_immediate
  end
  
  # only send email if cross audiences and the total lead is over 10,000
  def self.perform(action_id)
    action = Action.find_by_id(action_id)
    
    if action
      campaign = action.subject
      property = campaign.property
      property_ids = [property.id]
      hylet = campaign.first_nlt_hylet
      lead_groups = []
      
      # 1450259763879041875: required emails - bozzuto corporate
      required_group_ids = [1450259763879041875]
      
      hylet.audiences.each do |aud|
        next if required_group_ids.include?(aud.id)
        property_ids << aud.property_id
      end
      
      # return if not cross send
      return true if property_ids.uniq.count == 1
      
      hylet.audiences.each do |aud|
        next if !aud.property
        lead_groups << "- #{aud.property.name} #{aud.name} (#{aud.residents.count})"
      end
      
      total_leads = Audience.unique_leads_count( property.residents.or( hylet.audiences.collect{|a| a.residents.selector } ).selector )
      recipients = property.app_setting.spamish_emails
      recipients = [Notifier::DEV_ADDRESS] if recipients.empty?
      
      schedule = hylet.schedules.detect{|s| s["timestamp"].to_i == action.execute_at.to_i }

      if schedule && !schedule["subject"].blank?
        subject = schedule["subject"].values.first
      else
        subject = hylet.subject
      end
      
      pp "total_leads: #{total_leads}"
      if total_leads > 10000
        Notifier.system_message("Spamish Email Scheduled - #{Date.today.to_s}", 
          email_body(campaign, subject, action.execute_at, lead_groups), recipients, { "bcc" => Notifier::DEV_ADDRESS }).deliver_now
      end
    end
  end
  
  def self.email_body(campaign, subject, scheduled_time, lead_groups)
    
    return <<-MESSAGE
The following email with an audience greater than 10,000 leads contains cross-property lead groups.
This email could be considered spam by its recipient. Please review this email.

<br>
<br>
Email: <a href="#{campaign.dashboard_url}" target="_blank"> #{subject} </a> <br>
Scheduled Time: #{scheduled_time.to_s(:friendly_time)}
<br>
<br>
Lead Groups:
<br>
#{lead_groups.join(" <br>")}

<br>
<br>
<a href="#{campaign.dashboard_url}" target="_blank"> Review Email Now </a>
    MESSAGE
  end
  
end
