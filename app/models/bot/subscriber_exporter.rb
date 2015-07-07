class SubscriberExporter < ReportExporter
  
  def self.sendible?
    filter_events
    @events.count < 1000
  end
    
  def self.generate_csv
    lists = {
      "sent" => "SentList",
      "opened" => "OpenedList",
      "received" => "ReceivedList",
      "clicked" => "ClickedList",
      "unique_clicked" => "UniqueClickedList",
      "unsubscribed" => "UnsubscribedList",
      "complained" => "ComplainedList",
      "blacklisted" => "BlacklistedEvent",
      "bounced" => "BouncedList"
    }
    annotation = "#{@campaign.property.name}_#{@campaign.annotation}"
    file_name = "#{lists[@params["type"]]}_#{annotation.to_s.gsub(" ","")}_#{Time.now.strftime('%Y%m%d')}.csv"

    csv_string = CSV.generate() do |csv|  
      csv << ["Email", "Time (#{@campaign.property_setting.time_zone})"]
      
      filter_events
      
      query_count = @events.count
      current_page = 0
      step = 1000

      while query_count > 0
        evs = @events.order("created_at asc").offset(current_page * step).limit(step).all
        residents = Resident.with(:consistency => :eventual).where(:_id.in => evs.collect{|w| w.resident_id }.compact.uniq).collect{|e| e }
        
        evs.each do |ev|
          ev.eager_load(residents.detect{|e| e.id.to_i == ev.resident_id })
          csv << [ev.resident ? ev.resident.email : "This subscriber has been deleted", ev.created_at.to_s(:csv_time) ]
        end

        query_count-=step
        current_page+=1
      end
      
    end
    
    return csv_string, file_name
  end
  
  def self.perform(property_id, campaign_id, params)
    begin
      csv_string, file_name = init(Property.find(property_id), Campaign.find(campaign_id), params).generate_csv
      
      file_name = "#{MultiTenant.generate_id}_#{file_name}"

      File.open("#{TMP_DIR}#{file_name}", "wb") { |f| f.write(csv_string) }
      
      Notifier.system_message("[#{@property.name}] Subscribers Data",
        "Your file was exported successfully.
        <br><br> 
        <a href='http://#{HOST}/downloads/#{file_name}'>Download File</a> 
        <br><br> To protect your data the download link will work for the next two hours, or until you download the file
        <br>
        <br>
        CRM Help Team
        <br>
        help@hy.ly", @params["recipient"], {"from" => Notifier::EXIM_ADDRESS}).deliver_now

      Resque.enqueue_at(Time.now + 2.hours, DownloadCleaner, file_name)
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[SubscriberExporter] FAILURE", "ERROR DETAILS: #{error_details}",
        Notifier::DEV_ADDRESS, {"from" => Notifier::EXIM_ADDRESS}).deliver_now
        
      Notifier.system_message("[#{@property.name}] Subscribers Data",
        "There was an error while exporting your data, please contact help@hy.ly for help",
        @params["recipient"], {"from" => Notifier::EXIM_ADDRESS}).deliver_now
    end
  
  end
  
  def self.filter_events
    
    clzzes = {
      "sent" => SendEvent,
      "opened" => UniqueOpenEvent,
      "clicked" => LinkClickEvent,
      "unique_clicked" => UniqueLinkClickEvent,
      "unsubscribed" => UnsubscribeClickEvent,
      "complained" => ComplaintEvent,
      "blacklisted" => BlacklistedEvent,
      "bounced" => BounceEvent,
      "received" => SendEvent
    }

    @campaign.tmp_timestamp = @params["timestamp"]
    conditions = {:campaign_id => @campaign.multi_sends.collect{|c| c.id } }
    
    
    @events = clzzes[@params["type"]].where(conditions)
    @events = @events.where("opened_at IS NULL") if @params["type"] == "received"
  end
end
