class SendNewsletterAction
  extend Resque::Plugins::Retry
  @retry_limit = 5
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_scheduled
  end
  
  def self.redis_client
    @redis_client ||= begin
      yml = Rails.root.to_s + '/config/redis.yml'
      host = "localhost"
      port = 6379
    
      if File.exist? yml
        host, port = YAML.load_file(yml)[Rails.env].split(":", 2)
      end

      Redis.new(:host => host, :port => port)
    end
  end
  
  def self.send_now(campaign, published_at)
    
    action = DelayedAction.find_by(actor_id: campaign.property_id, subject_id: campaign.id)
    action.destroy if action
    
    action = DelayedAction.create! :user => campaign.user, :actor => campaign.property, :subject => campaign, :execute_at => published_at
      
    Resque.enqueue(SpamishEmailScheduled, action.id)
    
    Resque.enqueue_at(published_at, SendNewsletterAction, action.id)
    
  end
  
  def self.schedule(campaign, published_at)
    action = DelayedAction.create! :user => campaign.user, :actor => campaign.property, :subject => campaign, :execute_at => published_at
    
    Resque.enqueue(SpamishEmailScheduled, action.id)
    
    Resque.enqueue_at(published_at, SendNewsletterAction, action.id, "schedule")
    
    action
  end
  
  def self.perform(action_id, type = "send_now")
    action = DelayedAction.find_by_id(action_id)
    
    if action
      campaign = action.subject
      newsletter_hylet = campaign.first_nlt_hylet
      timestamp = nil
      
      if campaign
        if type == "schedule" #for schedule only
          
          schedules = newsletter_hylet.schedules
          current = schedules.detect{|s| s["action_id"].to_i == action.id }
          current["is_send"] = true
          timestamp = current["timestamp"].to_i if current["subject"] && !current["subject"].empty? #reschedule case
          
          newsletter_hylet.update_attributes(:email_project => {:schedules => schedules})
          
          if !campaign.is_published? && schedules.all?{|s| s["is_send"] }
            campaign.update_attributes(:is_published => true)
          end
        end
        
        enqueue(campaign, newsletter_hylet, timestamp)
        
      end

      action.destroy
      
    end #end if action
    
  end
  
  def self.batch_size(total)
    s = 10
    
    if total >= 10000
      s = 500
    elsif total >= 5000
      s = 250
    elsif total >= 1000
      s = 50
    elsif total >= 500
      s = 25
    elsif total >= 100
      s = 5
    elsif total >= 50
      s = 2
    end
    
    s
  end
  
  def self.enqueue(campaign, newsletter_hylet, timestamp = nil, start_at = nil, end_at = nil)
    first_batch = true
    property = campaign.property
    audiences = newsletter_hylet.audiences
    
    #send across superorg, property
    property_ids = []
    audiences.each do |a|
      property_ids << a.property_id.to_s
      
      if a.campaign && a.campaign.kind_of?(NewsletterCampaign)
        a.campaign.audience_counts.each do |ac|
          property_ids << ac["property_id"].to_s
        end
      end
    end
    property_ids.uniq!
    
    #cache audience counts
    audience_counts = audiences.collect{|audience|
      {"id" => audience.id, "name" => audience.name, "property_id" => audience.property_id, "count" => audience.residents.count}
    }
    
    #create NewsletterRescheduleCampaign for analytics
    #vc_ids is used to switch to the reschedule campaign when sending
    
    vc_ids = {}
    campaign.channel_variates.each do |v|
      vc_ids[v.variate_campaign_id] = v.variate_campaign_id
    end
    
    if timestamp #reschedule case
      
      #don't set parent_id for reschedule_root
      reschedule_root = NewsletterRescheduleCampaign.create({
        :property_id => campaign.property_id, 
        :user_id => campaign.user_id, 
        :group_id => campaign.id,
        :audience_counts => audience_counts,
        :published_at => Time.at(timestamp),
        :is_published => true
      })
      
      campaign.channel_variates.each do |v|
        variate_campaign = v.variate_campaign
        
        reschedule_campaign = NewsletterRescheduleCampaign.create({
          :property_id => reschedule_root.property_id, 
          :user_id => reschedule_root.user_id,
          :group_id => reschedule_root.group_id,
          :root_id => reschedule_root.id, 
          
          :parent_id => variate_campaign.id,
          :published_at => Time.at(timestamp),
          :is_published => true
        })
        
        reschedule_root.channel_variates.create(:variate_campaign_id => reschedule_campaign.id, :weight_percent => 100)
        
        vc_ids[variate_campaign.id] = reschedule_campaign.id
      end
      
    else
      campaign.update_attribute(:audience_counts, audience_counts)
      
    end
    
    quota = 750000
    now = Time.now.utc
    total = 0
    
    mailer_clzz = CampaignNewsletterMailer
    email_queue = :crm_newsletter
    
    # http://docs.mongodb.org/v2.4/core/cursors/#cursor-batches
    # - performance is bad when using skip, limit to iterate over large collection with the Audience.unique_leads_count, Audience.unique_leads_listing
    # - we can use mongodb cursor to iterate the collections, we may have the duplicated records when the resident get updated when the import,
    #    we need to use redis set to dedup the duplicated record within the audience and other audiences
    
    set_name = "newsletter_#{campaign.id}_#{MultiTenant.generate_id}" #must be unique
    
    audiences.each do |audience|
      residents = audience.residents.without(:activities)
      
      #lead nurturer
      if start_at && end_at
        residents = residents.where("sources" => {'$elemMatch' => {"created_at" =>  { '$gte' => start_at, '$lt' => end_at}} })
      end
      
      # collect resident id with cursor
      resident_ids = []
      residents.each do |e|
        resident_ids << e["_id"]
      end
      
      resident_ids.each_slice(5000).each do |arr|
        # redis set will ensure there is no duplicated id
        redis_client.sadd set_name, arr
      end
    end
    
    step = batch_size( redis_client.scard(set_name) )
    
    step = 500 if campaign.channel_variates.length == 1 #default to 500 if there is only one variant
    
    pp "redis_client.scard(set_name) #{redis_client.scard(set_name)}"
    
    redis_client.smembers(set_name).each_slice(step) do |batch_id|
      resident_ids = []
      
      Resident.with(:consistency => :eventual).where(:_id.in => batch_id).each do |resident|
        
        subscribed = resident.subscribed?(property) || !resident.subscribed?(property) && resident.any_subscribed?(property_ids)
        
        if subscribed && !resident.bad_email?
          total += 1
          resident_ids << resident.id
        end
      end
      
      num = ((total-1)/quota).to_i
      campaign_id = vc_ids[campaign.channel_random_variate.variate_campaign_id]
      
      if num == 0
        Resque.enqueue_to(email_queue, mailer_clzz, campaign_id, resident_ids, timestamp, first_batch)
        
      elsif !resident_ids.empty?
        Resque.enqueue_at_with_queue(email_queue, now + num.day, mailer_clzz, campaign_id, resident_ids, timestamp, first_batch)
        
      end
    
      first_batch = false
    end
    
    if total == 0 && audience_counts.sum{|a| a["count"] } > 0 && Time.now.utc > now + 5.minutes
      error = "Invalid send!! Long query may be killed at #{Time.now.utc} (executed at #{now}), audience_counts: #{audience_counts}"
      
      Notifier.system_message("[#{campaign.property.name}] SendNewsletterAction - FAILURE",
        "campaign id: #{campaign.id}, campaign name: #{campaign.annotation} <br><br> ERROR DETAILS: #{error}", Notifier::DEV_ADDRESS).deliver_now
      
      raise error
    end
    
    #remove redis key
    redis_client.del set_name
    
    notification_emails = campaign.notification_emails.uniq.reject{|e| e.blank? }

    if ["NewsletterCampaign"].include?(campaign.class.to_s)
      Notifier.system_message("[#{property.name}] Newsletter Status: Sent", email_body(campaign, newsletter_hylet, total, audience_counts, now),
        notification_emails, {"bcc" => Notifier::DEV_ADDRESS}).deliver_now
        
      # import recpients for the spam watch report
      import_recpient_at = Time.now + ((total*60/10000) + 15).minutes
      campaign.multi_sends.each do |c|
        Resque.enqueue_at(import_recpient_at, RecipientImporter, c.id)
      end
      
    end
  end
  
  def self.email_body(campaign, newsletter_hylet, total, audience_counts, executed_at)
    executed_at = executed_at.in_time_zone(campaign.property_setting.time_zone)
    
    audiences = audience_counts.collect{|a| "#{Property.find(a["property_id"]).name} #{a["name"]} (#{a["count"]})" }.join(" + ")
    
    return <<-MESSAGE
    
- Property:  #{campaign.property.name} <br>
- Subject:  <a href="#{campaign.dashboard_url}">#{newsletter_hylet.last_subject}</a> <br>
- Audience: #{audiences}<br>
- Sent:  #{total} <br>
- Date:  #{executed_at.strftime("%m/%d/%Y")} at #{executed_at.strftime("%l:%M %p")} <br>

<br>
<br>
CRM Help Team
<br>
help@hy.ly
    MESSAGE
  end
  
end