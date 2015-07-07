class VariationMetricGenerator
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_medium
  end
  
  def self.perform(etime = Time.now.utc.to_i)
    begin
      time = Time.at(etime).utc
      time = time - time.min.minutes - time.sec.seconds #end of time-zone day
      start_at = time - 1.day
      end_at = time - 1.second

      midnight_time_zones = UtcOffset.midnight_time_zones(time.hour)
      
      Campaign.where("time_zone IN (?) AND type IN('NewsletterCampaign', 'NewsletterRescheduleCampaign') AND
                      deleted_at IS NULL AND parent_id IS NULL AND root_id IS NULL", midnight_time_zones
                    ).joins("INNER JOIN property_settings ON campaigns.property_id = property_settings.property_id").each do |campaign|
        
        Time.zone = campaign.property_setting.time_zone
        
        mark_send_as_opened(campaign, start_at, end_at)
        calculate_newsletter_stats(campaign, start_at, end_at)
        
      end
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"
      
      Resque.enqueue(SystemMessageMailer, "[VariationMetricGenerator] FAILURE", error_details)
    end
    
  end
  
  def self.mark_send_as_opened(campaign, start_at, end_at)
    # Mark send event as opened if it was not
    UniqueOpenEvent.find_in_batches(:conditions => "campaign_id = #{campaign.id} AND created_at #{(start_at..end_at).to_s(:db)}") do |events|
      events.each do |ev|
        ev.send(:update_send_event)
      end
    end
  end
  
  def self.calculate_newsletter_stats(campaign, start_at, end_at)
    
    #CampaignVariationMetric
    dict = {
      "SendEvent" => "sends_count",
      "UniqueOpenEvent" => "unique_opens_count",
      "OpenEvent" => "opens_count",
      "UnsubscribeClickEvent" => "unsubscribes_count",
      "LinkClickEvent" => "clicks_count" ,
      "UniqueLinkClickEvent" => "unique_clicks_count" ,
      "BlacklistedEvent" => "blacklisted_count",
      "ComplaintEvent" => "complaints_count",
      "BounceEvent" => "bounces_count"
    }
    
    Event.where("campaign_id = ? AND created_at #{(start_at..end_at).to_s(:db)}", campaign.id).select('count(id) as events_count,
      type, campaign_variation_id, campaign_id').group('type, campaign_variation_id').each do |row|
 
      if row.campaign_variation_id && dict[row.type]
        variation_metric = CampaignVariationMetric.where("created_at #{(start_at..end_at).to_s(:db)} AND
          campaign_id = #{row.campaign_id} AND variation_id = #{row.campaign_variation_id}").first
          
        if variation_metric
          variation_metric.update_attributes({ dict[row.type] => row.events_count })
        else
          CampaignVariationMetric.create :campaign_id => row.campaign_id, dict[row.type] => row.events_count,
            :variation_id => row.campaign_variation_id, :created_at => end_at
        end
      end
      
    end
    
    
    
    #BrowserVariationMetric, OsVariationMetric, CountryVariationMetric, ResponseTimeVariationMetric
    clicks_hash = {}
    ["browser", "resolution", "os", "country", "response_time", "url_id", "url_id2"].each do |column|
      clzz = case column
        when "browser"
          BrowserVariationMetric
        when "resolution"
          ResolutionVariationMetric
        when "os"
          OsVariationMetric
        when "country"
          CountryVariationMetric
        when "response_time"
          ResponseTimeVariationMetric
        when "url_id"
          LinkClickVariationMetric
        when "url_id2"
          UniqueLinkClickVariationMetric
      end
      
      #UniqueOpenEvent store ip, country, browser, resolution
      event_clzz = case column
        when "url_id"
          LinkClickEvent
        when "url_id2"
          column = "url_id" #remove temp url_id2 hack
          
          UniqueLinkClickEvent
        else
          UniqueOpenEvent
      end
      
      event_clzz.where("campaign_id = ? AND created_at #{(start_at..end_at).to_s(:db)}", campaign.id).select('count(id) as events_count,
          campaign_variation_id, campaign_id, browser, resolution, os, country, response_time, url_id').group("#{column}, campaign_variation_id").each do |row|
        
        text = row[column]
        
        if column == "url_id"
          if text
            url = Url.find_by_id(text)
            text = url.origin_url if url
          end
          
          # accumulate clicks count
          if clicks_hash[text]
            clicks_hash[text] += row.events_count
          else
            clicks_hash[text] = row.events_count
          end
        end
        
        if row.campaign_variation_id
          if !text.blank?
            variation_metric = clzz.where(["created_at #{(start_at..end_at).to_s(:db)} AND
              campaign_id = #{row.campaign_id} AND variation_id = #{row.campaign_variation_id} AND text = ?", text]).first
          else
            variation_metric = clzz.where(["created_at #{(start_at..end_at).to_s(:db)} AND
              campaign_id = #{row.campaign_id} AND variation_id = #{row.campaign_variation_id} AND text IS NULL"]).first
          end
          
          if variation_metric
            variation_metric.update_attributes({ :events_count => column == "url_id" ? clicks_hash[text] : row.events_count, :text => text })
            
          else
            clzz.create :campaign_id => row.campaign_id, :events_count => row.events_count,
              :text => text, :variation_id => row.campaign_variation_id, :created_at => end_at
          end
        end
      
      end
    end
    
  end
  
  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(1)
  end
  
end
