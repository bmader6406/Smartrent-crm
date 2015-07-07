class RecipientImporter
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_import
  end
  
  def self.perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    
    send_events = SendEvent.where(:campaign_id => campaign.id)
    recipients_count = Recipient.where(:campaign_id => campaign.id).count
    
    if recipients_count == 0 && recipients_count < send_events.count # update
      
      # build audience_id and status dict
      resident_dict = {}
      
      campaign.first_nlt_hylet.audiences.each do |audience|
        selector = audience.residents.selector
        # remove subscsribed, email_check
        selector = recursive_delete(selector, "subscribed")
        selector = recursive_delete(selector, "email_check")
        
        Resident.with(:consistency => :eventual).only(:_id, :unified_status, :properties).where(selector).each do |r|
          status = nil
          prop = r.properties.detect{|p| p.property_id.to_i == audience.property_id }
          
          if prop && ["current", "future", "past", "notice"].include?(prop.status.to_s.downcase)
            status = "resident_#{prop.status.downcase}"
              
          else
            status = r.unified_status
          end
          
          resident_dict[r._id.to_i] = {:audience_id => audience.id, :status => status}
        end
      end
      
      # build recipient array to import
      recipient_col = [:id, :campaign_id, :audience_id, :resident_id, :status]
      
      query_count = send_events.count
      current_page = 0
      step = 1000
      
      while query_count > 0
        recipient_val = [] #[:campaign_id, :audience_id, :resident_id, :status]
        
        send_events.order("created_at asc").offset(current_page * step).limit(step).each do |ev|
          recipient_val << [
            ev.id, 
            ev.campaign_id,
            (resident_dict[ev.resident_id][:audience_id] rescue nil),
            ev.resident_id,
            (resident_dict[ev.resident_id][:status] rescue nil)
          ]
        end

        Recipient.import recipient_col, recipient_val, :validate => false if !recipient_val.empty?
        
        query_count-=step
        current_page+=1
      end
    end
  end
  
  def self.recursive_delete(hash, key)
    if hash.is_a?(Hash)
      hash.inject({}) do |m, (k, v)|
        m[k] = recursive_delete(v, key) unless k == key
        m
      end
    elsif hash.is_a?(Array)
      hash.map! {|h| recursive_delete(h, key) }

    else
      hash
    end
  end
end