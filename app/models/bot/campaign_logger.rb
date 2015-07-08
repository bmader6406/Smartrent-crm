# This queue will be queued by the BatchEnqueuer

class CampaignLogger
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_logger_batch
  end
  
  def self.perform(campaign_id, action, params)
    # params type is
    # - array: track_click
    # - array: track_open
    
    return true if campaign_id.zero?
    
    if action == "track_click"
      campaign = Campaign.find(campaign_id)
      
      params.each do |param|
        next if !Resident.with(:consistency => :eventual).find_by_id(param["rid"])
        
        attrs = {
          :property_id => campaign.property_id,
          :campaign_id => campaign.id,
          :resident_id => param["rid"],
          :url_id => param["url_id"],
          :created_at => Time.at(param["request_time"].to_i)
        }
        
        LinkClickEvent.create(attrs)
        
        #must be below click event (wait for click activity created)
        unique_click = UniqueLinkClickEvent.find_by_campaign_id_and_resident_id(campaign.id, param["rid"])

        if !unique_click
          UniqueLinkClickEvent.create(attrs)
        end

      end
      
    elsif action == "track_open"
      campaign = Campaign.find(campaign_id)
      
      params.each do |param|
        next if !Resident.with(:consistency => :eventual).find_by_id(param["rid"])
        next if param["visitor_ip"].blank?
        
        location = JSON.parse(open("http://atics.hy.ly:8000/location.json?visitor_ip=#{param["visitor_ip"]}").read)

        if location && !location["error"]
          attrs = {
            :property_id => campaign.property_id,
            :campaign_id => campaign.id,
            :resident_id => param["rid"],
            :created_at => Time.at(param["request_time"].to_i)
          }

          OpenEvent.create(attrs)

          #must be below open event (wait for open activity created)
          unique_open = UniqueOpenEvent.find_by_campaign_id_and_resident_id(campaign.id, param["rid"])

          if !unique_open
            user_agent = UserAgent.parse(param["user_agent"])

            attrs[:browser] = user_agent.browser
            attrs[:os] = user_agent.platform
            attrs[:ip] = param["visitor_ip"]
            attrs[:country] = location["country_name"]

            UniqueOpenEvent.create(attrs)
          end

          #TODO: track geomap
        end
      end
      
    end # / if action
    
  end
  
end
