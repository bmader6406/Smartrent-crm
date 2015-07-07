class SpamishEmailSent
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_medium
  end
  
  def self.perform(etime = Time.now.utc.to_i)
    begin
      time = Time.at(etime).utc
      midnight_time_zones = UtcOffset.midnight_time_zones(time.hour)
      
      PropertySetting.where(:time_zone => midnight_time_zones).includes(:property).each do |setting|
        report_emails(setting.property, time)
      end
      
      return "ok"
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace

      pp "ERROR: ", error_details
      
      Resque.enqueue(SystemMessageMailer, "[SpamishEmailSent] FAILURE", error_details)
    end    
  end
  
  # only send email if cross audiences and the total lead is over 10,000
  def self.report_emails(property, time)
    start_at = time.in_time_zone.beginning_of_day - 2.day
    end_at = time.in_time_zone.end_of_day - 1.day
    pp "start_at: #{start_at}, end_at: #{end_at}"
    
    all_properties = [property]
    property.tenant.properties.includes(:property).each do |prop|
      all_properties << prop.property
    end

    property_ids = all_properties.collect{|p| p.id }

    all_audiences = Audience.where(:property_id => property_ids).includes(:campaign).all

    nlt_campaigns = Campaign.unscoped.where(:property_id => property_ids).where("root_id IS NULL AND type IN ('NewsletterCampaign', 'NewsletterRescheduleCampaign') AND 
      published_at #{(start_at..end_at).to_s(:db)} AND sends_count > 0 AND deleted_at IS NULL").order("published_at desc").all

    root_va_ids = Campaign.where(:root_id => nlt_campaigns.collect{|c| [c.id, c.group_id] }.flatten.compact.uniq, :parent_id => nil).collect{|c| [c.root_id, c.id] }

    # build newsletter hylet dict
    nlt_dict = {}

    NewsletterHylet.where(:campaign_id => root_va_ids.collect{|r| r[1] }.uniq ).all.each do |hylet|
      root_id = root_va_ids.detect{|r| r[1] == hylet.campaign_id}[0]

      nlt_dict[root_id] = hylet
    end
    
    # build email body
    stats = []
    nlt_campaigns.each do |campaign| 
      root_id = campaign.kind_of?(NewsletterRescheduleCampaign) ? campaign.group_id : campaign.id
      nlt_hylet = nlt_dict[root_id]

      if nlt_hylet
        schedule = nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == campaign.published_at.to_i }

        if schedule && !schedule["subject"].blank?
          subject = schedule["subject"].values.first
        else
          subject = nlt_hylet.subject
        end

      else
        subject = "<deleted>"
      end 
      
      spam_index = conversion(campaign.unsubscribes_count - campaign.clicks_count, campaign.clicks_count)
      complaint_percent = conversion(campaign.complaints_count, campaign.sends_count)
      
      if complaint_percent > 0.04 && campaign.complaints_count > 2 && campaign.unsubscribes_count > 10 && spam_index > 0
      
        pp "subject: #{subject} - #{campaign.published_at.to_s(:friendly_time)} 
              - complaint: #{campaign.complaints_count} (#{complaint_percent}%), 
              - unsub: #{campaign.unsubscribes_count}
              - index: #{spam_index}"
              
        dashboard_url = "http://#{HOST}/properties/#{campaign.property_id}/notices/#{root_id}/dashboard"
        spam_watch_url = "http://#{HOST}/properties/#{campaign.property_id}/notices/#{root_id}/reports/spam_watch?timestamp=#{campaign.published_at.to_i}"
        
        stat = "Email: <a href='#{spam_watch_url}' target='_blank'> #{subject} </a> <br>"
        stat << "- Deployment Time: #{campaign.published_at.to_s(:friendly_time) }<br>"
        stat << "- <a href='#{campaign.preview_url}' target='_blank'> View Email </a> <br>"
        stat << "Metrics: <br>"
        stat << "- Sent: #{number_with_delimiter(campaign.sends_count)} <br>"
        stat << "- Unique Opens: #{number_with_delimiter(campaign.unique_opens_count)} (#{ conversion(campaign.unique_opens_count, campaign.sends_count) }%) <br>"
        stat << "- Clicks:  #{number_with_delimiter(campaign.clicks_count)} (#{ conversion(campaign.clicks_count, campaign.sends_count) }%) <br>"
        stat << "- Unsubscribes:  #{number_with_delimiter(campaign.unsubscribes_count)} (#{ conversion(campaign.unsubscribes_count, campaign.sends_count) }%) <br>"
        stat << "- Spam Index: #{spam_index} <br>"
        stat << "- Complaints: #{number_with_delimiter(campaign.complaints_count)} (#{complaint_percent}%) <br>"
        stat << "- <a href='#{spam_watch_url}' target='_blank'> View Report </a> <br>"
        stat << "Lead Group: <br>"
      
        cache_audiences = campaign.audience_counts

        if cache_audiences.length > 0
          audiences = Audience.where(:id => cache_audiences.collect{|a| a["id"]}).includes(:property, :campaign).all

          sent_audiences = cache_audiences.collect{|c|
            a = audiences.detect{|a| a.id == c["id"].to_i}

            if a #existing
              "#{a.long_name} (#{c["count"]})"

            else #deleted audience
              property = Property.find_by_id(c["property_id"])

              if property
                "#{property.name} #{c["name"]} (#{c["count"]})"
              else
                "#{c["name"]} (#{c["count"]})"
              end
            end
          }
        
        else
          sent_audiences = campaign.first_nlt_hylet.audiences.collect{|a| a.long_name }
        
        end
      
        sent_audiences.each do |str|
          stat << "- #{str} <br>"
        end
      
        stats << stat
      end
    end
    
    recipients = property.setting.spamish_emails
    recipients = [Notifier::DEV_ADDRESS] if recipients.empty?
    
    if stats.length > 0
      Notifier.system_message("#{property.name.gsub(" Group", "")} Reputation: Spam Watch Alert (#{Date.today.to_s})", 
        email_body(property, stats), recipients, { "bcc" => Notifier::DEV_ADDRESS }).deliver_now
    else
      Notifier.system_message("#{property.name.gsub(" Group", "")} Reputation: Spam Watch - Good News (#{Date.today.to_s})", 
        congrat_body, recipients, { "bcc" => Notifier::DEV_ADDRESS }).deliver_now if nlt_campaigns.length > 0
        
      pp "No spamish email found! #{Time.now}"
    end
  end
  
  def self.number_with_delimiter(num)
    ActionController::Base.helpers.number_with_delimiter(num)
  end
  
  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
  end 
  
  def self.email_body(property, stats)
    return <<-MESSAGE
This report gives you emails sent in the past 48 hours where the Spam Index is positive (more people disliked the email than clicked on it.)
OR the complaints are greater than 0.04% (the threshold should be 0.02%)
<br>
<br>
#{stats.join(" <br><br> ")}

    MESSAGE
  end
  
  def self.congrat_body
    return <<-MESSAGE
Hooray... All emails sent in the past 48 hours are well under the Complaints and Spam Index thresholds.
<br>
<br>
Congratulations, everyone!

    MESSAGE
  end
end
