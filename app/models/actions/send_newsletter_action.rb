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
    
    Resque.enqueue_at(published_at, SendNewsletterAction, action.id)
    
  end
  
  def self.schedule(campaign, published_at)
    action = DelayedAction.create! :user => campaign.user, :actor => campaign.property, :subject => campaign, :execute_at => published_at
    
    Resque.enqueue_at(published_at, SendNewsletterAction, action.id, "schedule")
    
    action
  end
  
  def self.perform(action_id, type = "send_now")
    action = DelayedAction.find_by_id(action_id)
    campaign = action.subject
    
    if campaign
      campaign.update_attributes(:is_published => true)
      enqueue(campaign)
    end

    action.destroy
  end
  
  def self.enqueue(campaign)
    first_batch = true
    property = campaign.property
    audiences = campaign.audiences
    
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
    
    campaign.update_attribute(:audience_counts, audience_counts)
    
    quota = 750000
    now = Time.now.utc
    total = 0
    
    mailer_clzz = CampaignNewsletterMailer
    email_queue = :crm_newsletter
    
    # http://docs.mongodb.org/v2.4/core/cursors/#cursor-batches
    # - performance is bad when using skip, limit to iterate over large collection with the Audience.unique_residents_count, Audience.unique_residents_listing
    # - we can use mongodb cursor to iterate the collections, we may have the duplicated records when the resident get updated when the import,
    #    we need to use redis set to dedup the duplicated record within the audience and other audiences
    
    set_name = "newsletter_#{campaign.id}_#{MultiTenant.generate_id}" #must be unique
    
    audiences.each do |audience|
      residents = audience.residents.without(:activities)
      
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
    
    step = 500
    
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
      
      if num == 0
        Resque.enqueue_to(email_queue, mailer_clzz, campaign.id, resident_ids, first_batch)
        
      elsif !resident_ids.empty?
        Resque.enqueue_at_with_queue(email_queue, now + num.day, mailer_clzz, campaign.id, resident_ids, first_batch)
        
      end
    
      first_batch = false
    end
    
    if total == 0 && audience_counts.sum{|a| a["count"] } > 0 && Time.now.utc > now + 5.minutes
      error = "Invalid send!! Long query may be killed at #{Time.now.utc} (executed at #{now}), audience_counts: #{audience_counts}"
      
      Notifier.system_message("[#{campaign.property.name}] SendNewsletterAction - FAILURE",
        "campaign id: #{campaign.id}, campaign name: #{campaign.subject} <br><br> ERROR DETAILS: #{error}", Notifier::DEV_ADDRESS).deliver_now
      
      raise error
    end
    
    #remove redis key
    redis_client.del set_name
    
    if ["NewsletterCampaign"].include?(campaign.class.to_s)
      Notifier.system_message("[#{property.name}] Newsletter Status: Sent", email_body(campaign, total, audience_counts, now),
        campaign.property.setting.notification_emails.uniq.reject{|e| e.blank? }, {"bcc" => Notifier::DEV_ADDRESS}).deliver_now      
    end
  end
  
  def self.email_body(campaign, total, audience_counts, executed_at)
    executed_at = executed_at.in_time_zone(campaign.property_setting.time_zone)
    
    audiences = audience_counts.collect{|a| "#{Property.find(a["property_id"]).name} #{a["name"]} (#{a["count"]})" }.join(" + ")
    
    return <<-MESSAGE
    
- Property:  #{campaign.property.name} <br>
- Subject:  <a href="#{campaign.dashboard_url}">#{campaign.subject}</a> <br>
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