class EmailStatExporter < ReportExporter
  
  def self.generate_csv
    csv_string = nil
    file_name = nil
    annotation = "#{@campaign.property.name}_#{@campaign.annotation}"
    
    case @params["type"]
      when "variant_analysis"
        
        variates = @campaign.dict_variates["email"].first || []
        
        campaigns = variates.collect{|v| v.variate_campaign }
        campaigns.each{|c| c.tmp_timestamp = @params["timestamp"] }
        
        total_sends = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_sends_count } }
        total_opens = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_unique_opens_count } }
        total_clicks = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_unique_clicks_count } }
        total_unsubscribes = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_unsubscribes_count } }
        total_blacklisted = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_blacklisted_count } }
        total_complaints = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_complaints_count } }
        total_bounces = campaigns.sum{|c| c.variant_sends.sum{|c2| c2.variant_bounces_count } }
        
        csv_string = CSV.generate() do |csv|  
          csv << ["Variant", "# of Sent", "# of Opens", "% of Opens", "# of Clicks", "% of Clicks",
                  "# of Unsubscribes", "% of Unsubscribes", "# of Blacklisted", "% of Blacklisted",
                  "# of Complaints", "% of Complaints", "# of Bounces", "% of Bounces"]
                  
          campaigns.each_with_index do |campaign, index|
            sends_count = campaign.variant_sends.sum{|c| c.variant_sends_count}
            opens_count = campaign.variant_sends.sum{|c| c.variant_unique_opens_count}
            clicks_count = campaign.variant_sends.sum{|c| c.variant_unique_clicks_count}
            unsubscribes_count = campaign.variant_sends.sum{|c| c.variant_unsubscribes_count}
            blacklisted_count = campaign.variant_sends.sum{|c| c.variant_blacklisted_count}
            complaints_count = campaign.variant_sends.sum{|c| c.variant_complaints_count}
            bounces_count = campaign.variant_sends.sum{|c| c.variant_bounces_count}
            
            
            csv << [variates[index].version,
                    sends_count,
                    opens_count, conversion(opens_count, sends_count),
                    clicks_count, conversion(clicks_count, sends_count),
                    unsubscribes_count, conversion(unsubscribes_count, sends_count), 
                    blacklisted_count, conversion(blacklisted_count, sends_count),
                    complaints_count, conversion(complaints_count, sends_count),
                    bounces_count, conversion(bounces_count, sends_count)]
          end
          
          csv << ["Total",
                  total_sends,
                  total_opens, conversion(total_opens, total_sends),
                  total_clicks, conversion(total_clicks, total_sends),
                  total_unsubscribes, conversion(total_unsubscribes, total_sends), 
                  total_blacklisted, conversion(total_blacklisted, total_sends),
                  total_complaints, conversion(total_complaints, total_sends),
                  total_bounces, conversion(total_bounces, total_sends)]
        end
        
        file_name = "VariantAnalysisReport_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"
      
      when "link_clicks"
        clicks = []
        
        metrics = variation_metrics.where("type IN ('LinkClickVariationMetric') AND text IS NOT NULL AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text").all
          
        total_events = metrics.sum{|m| m.total_events.to_i}

        metrics.each do |m|
          clicks << {:name => m.text, :count => m.total_events, :conversion => conversion(m.total_events, total_events)}
        end
      
        clicks.sort!{|a, b| b[:count] <=> a[:count]}
        
        csv_string = CSV.generate() do |csv|  
          csv << ["Link", "# of Clicks", "% of Clicks"]
                
          clicks.each_with_index do |m, index|
            csv << [m[:name], m[:count], m[:conversion]]
          end                      
          
          total = clicks.sum{|m| m[:count]}
          csv << ["Total", total, total > 0 ? 100 : 0]
        end
          
        file_name = "LinkClickReport_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"
        
      when "opens_by_browser"
        opens = []
        
        metrics = variation_metrics.where("type IN ('BrowserVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text").all
          
        total_events = metrics.sum{|m| m.total_events.to_i}

        metrics.each do |m|
          opens << {:name => m.text, :count => m.total_events, :conversion => conversion(m.total_events, total_events)}
        end
      
        opens.sort!{|a, b| b[:count] <=> a[:count]}
        
        csv_string = CSV.generate() do |csv|  
          csv << ["Agent", "# of Opens", "% of Opens"]
                
          opens.each_with_index do |m, index|
            csv << [m[:name], m[:count], m[:conversion]]
          end
          
          total = opens.sum{|m| m[:count]}
          csv << ["Total", total, total > 0 ? 100 : 0]

        end
      
        file_name = "OpenByBrowserReport_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"
        
      when "opens_by_os"
        opens = []
        
        metrics = variation_metrics.where("type IN ('OsVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text").all
          
        total_events = metrics.sum{|m| m.total_events.to_i}

        metrics.each do |m|
          opens << {:name => m.text, :count => m.total_events, :conversion => conversion(m.total_events, total_events)}
        end
      
        opens.sort!{|a, b| b[:count] <=> a[:count]}
        
        csv_string = CSV.generate() do |csv|  
          csv << ["OS", "# of Opens", "% of Opens"]
                
          opens.each_with_index do |m, index|
            csv << [m[:name], m[:count], m[:conversion]]
          end
          
          total = opens.sum{|m| m[:count]}
          csv << ["Total", total, total > 0 ? 100 : 0]

        end
      
        file_name = "OpenByOSReport_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"
        
      when "opens_by_country"
        opens = []
        
        metrics = variation_metrics.where("type IN ('CountryVariationMetric') AND events_count > 0").select("variation_id, type, text,
            sum(events_count) as total_events").group("text").all
          
        total_events = metrics.sum{|m| m.total_events.to_i}

        metrics.each do |m|
          opens << {:name => m.text, :count => m.total_events, :conversion => conversion(m.total_events, total_events)}
        end
      
        opens.sort!{|a, b| b[:count] <=> a[:count]}
        
        csv_string = CSV.generate() do |csv|  
          csv << ["Country", "# of Opens", "% of Opens"]
                
          opens.each_with_index do |m, index|
            csv << [m[:name], m[:count], m[:conversion]]
          end
          
          total = opens.sum{|m| m[:count]}
          csv << ["Total", total, total > 0 ? 100 : 0]

        end
        
        file_name = "OpenByCountryReport_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"

    end
    
    return csv_string, file_name
    
  end
  
  def self.perform(campaign_id, start_at, end_at)

    
    begin

    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[EmailStatExporter] FAILURE", "ERROR DETAILS: #{error_details}",
        Notifier::DEV_ADDRESS, {"from" => Notifier::EXIM_ADDRESS}).deliver_now
    end
  
  end
  
end
