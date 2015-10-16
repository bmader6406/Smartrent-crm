class CampaignNewsletterMailer < QueuedMailer
  
  def self.queue
    :crm_newsletter
  end
  
  def self.perform(campaign_id, resident_ids, first_batch = false)
    
    return true if resident_ids.empty?
    
    campaign = Campaign.find(campaign_id)
    property = campaign.property
    
    app_setting = PropertySetting.app_setting
    
    
    send_col = [:type, :property_id, :campaign_id, :resident_id, :mimepart, :executed_time, :message_id]
    send_val = []
    send_ids = []
    
    blacklisted_col = [:type, :property_id, :campaign_id, :resident_id]
    blacklisted_val = []
    blacklisted_ids = []
    
    Resident.with(:consistency => :eventual).where(:_id.in => resident_ids).each_with_index do |resident, index|
      
      resident.context(campaign)
      
      bcc_emails = []
      
      if index == 0
        
        #bcc every batch
        if resident_ids.length > 100
          bcc_emails = [Notifier::DEV_ADDRESS]
        end
      end
      
      res = unsubscribe_resident_if_blacklisted(resident, campaign) { 
        Notifier.campaign_newsletter(campaign, resident, { :bcc_emails => bcc_emails }).deliver_now
      }

      if res[:mimepart]
        send_val << ["SendEvent", campaign.property_id, campaign.id, resident.id, res[:mimepart], res[:executed_time], res[:message_id]]
        send_ids << resident.id
      
      elsif res[:blacklisted]
      
        blacklisted_val << ["BlacklistedEvent", campaign.property_id, campaign.id, resident.id]
        blacklisted_ids << resident.id
      end
      
    end
    
    #bulk import
    import_activities(property, campaign, send_ids, "send_mail")
    import_activities(property, campaign, send_ids, "blacklist") if !blacklisted_ids.empty?
    
    SendEvent.import send_col, send_val, :validate => false if !send_val.empty?
    BlacklistedEvent.import blacklisted_col, blacklisted_val, :validate => false if !blacklisted_val.empty?
    
    #update counters
    
    Campaign.update_counters campaign.id, SendEvent.attr_count => send_val.length, BlacklistedEvent.attr_count => blacklisted_val.length
      
    
  end
  
  def self.import_activities(property, campaign, resident_ids, action)
    prop_resident_ids = {}
    
    attrs = {
      :_id => BSON::ObjectId.new,
      :action => action,
      :subject_id => campaign.id,
      :subject_type => campaign.class.to_s,
      :created_at => Time.now.utc,
      :updated_at => Time.now.utc
    }
    
    #pp ">>>", resident_ids, attrs
    
    Resident.with(:consistency => :eventual).where(:_id.in => resident_ids).each do |resident|
      prop = nil
      
      if !resident.properties.empty?
        prop = resident.properties.detect{|p| p.property_id.to_i == property.id }
      
        #find prop from cross property send
        if !prop
          audience = resident.to_cross_audience(campaign)
        
          if audience && audience.property_id
            prop = resident.properties.detect{|p| p.property_id.to_i == audience.property_id }
          end
        end
      end
      
      if prop
        property_id = prop.property_id
      else
        property_id = property.id.to_s
      end
      
      if prop_resident_ids[property_id]
        prop_resident_ids[property_id] << resident.id
      else
        prop_resident_ids[property_id] = [resident.id]
      end
      
      #set lead score only if it is a newsletter send
      if action == "send_mail" && campaign.kind_of?(NewsletterCampaign)
        if prop
          prop.sends_count += 1
          prop.finalize_score
        else
          resident.sends_count += 1
          resident.finalize_score
        end
      end
    end
    
    prop_resident_ids.keys.each do |prop_id|
      attrs[:property_id] = prop_id

      Resident.collection.where({"_id" => {"$in" => prop_resident_ids[prop_id] }}).update({
          '$inc' => {"marketing_activities_count" => 1}, 
          "$push" => {"marketing_activities" => attrs}
        }, {:multi => true, :upsert => true})
    end
  end
  
end