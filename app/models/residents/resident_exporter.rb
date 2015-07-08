require 'csv'

class ResidentExporter
  def self.queue
    :crm_immediate
  end
  
  def self.sendible?
    residents_count < 1000
  end
  
  def self.pipeline
    project = { "_id" => 1, "properties._id" => 1 }
    
    Resident::CORE_FIELDS.each do |f|
      project[f] = 1
    end
    
    Resident::PROPERTY_FIELDS.each do |f|
      project["properties.#{f}"] = 1
    end
    
    match1 = {
      "properties" => {
        '$elemMatch' => {
          "property_id" => {"$in" => @params["property_ids"] }
        }
      }
    }

    match2 = {
      "properties.property_id" => {"$in" => @params["property_ids"] }
    }
    
    # statuses
    if !@params["statuses"].blank?
      match1["properties"]["$elemMatch"]["status"] = {"$in" => @params["statuses"] }
      match2["properties.status"] = {"$in" => @params["statuses"] }
    end
    
    # move in range
    if !@params["move_in"].blank?
      start_date, end_date = @params["move_in"].split(" - ")
      start_date = Date.parse(start_date).to_time
      end_date = Date.parse(end_date).to_time
      
      match1["properties"]["$elemMatch"]["move_in"] = { "$gte" => start_date, "$lte" => end_date }
      match2["properties.move_in"] = { "$gte" => start_date, "$lte" => end_date }
    end
    
    # birthday
    if @params["type"] == "birthday"
      # prepare month field for match2
      project["month"] = {"$month" => "$birthday"}
      project["day_of_month"] = {"$dayOfMonth" => "$birthday"}
      
      # make sure birthday is a Date
      match1["birthday"] = {"$type" => 9}
    end
    
    if !@params["month"].blank?
      @params["month"] = @params["month"].collect{|m| m.to_i }
      
      match2["month"] = {"$in" => @params["month"] }
    end
    
    # rental type
    if !@params["rental_types"].blank?
      match1["properties"]["$elemMatch"]["rental_type"] = {"$in" => @params["rental_types"] }
      match2["properties.rental_type"] = {"$in" => @params["rental_types"] }
    end
    
    return [
      { "$match" => match1 },
      { "$project" => project },
      { "$unwind" => "$properties"},
      { "$match" => match2 }
    ]
  end
  
  def self.residents_count
    Resident.with(:consistency => :eventual).collection.aggregate(pipeline + [
      { "$group" => { :_id => "$properties._id" } },
      { "$group" => { :_id => 1, :count => { "$sum" => 1 } } }
    ])[0]["count"] rescue 0
  end
  
  def self.residents_listing(limit, skip)
    sort = { "first_name" => 1, "_id" => 1 }
    
    if @params["type"] == "birthday"
      sort = { "month" => 1, "day_of_month" => 1, "_id" => 1 }
      
    elsif @params["type"] == "emails"
      sort = { "properties.move_in" => 1, "_id" => 1 }
    end
    
    Resident.with(:consistency => :eventual).collection.aggregate(pipeline + [
      { "$sort" => sort }, #must have sort
      { "$limit" => limit },
      { "$skip" => skip }
    ])
  end
  
  def self.age(dob)
    if (dob.year rescue false)
      today = Date.today
      age = today.year - dob.year
      age -= 1 if dob.strftime("%m%d").to_i > today.strftime("%m%d").to_i
      age
    else
      "N/A"
    end
  end
  
  def self.init(params)
    @params = params
    
    return self
  end

  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
  end
  
  def self.generate_csv
    file_name = "#{@params["type"]}Report_#{Time.now.strftime('%Y%m%d')}.csv"

    csv_string = CSV.generate() do |csv|  
      per_page = 250
      current_page = 0
      query_count = residents_count
      
      property_dict = {}
      unit_dict = {}

      Property.where(:id => @params["property_ids"]).each do |p|
        property_dict[p.id.to_s] = p.name
      end

      Unit.where(:property_id => @params["property_ids"]).each do |u|
        unit_dict[u.id.to_s] = u.code
      end
      
      if @params["type"] == "emails"
        csv << ["Property Name", "Full Name", "Unit #" , "Address", "City", "State", "Zip", "Status", "Email", "Move In"]
        
      elsif @params["type"] == "birthday"
        csv << ["Property Name", "Full Name", "Email", "Address", "City", "State", "Zip", "Birthday", "Age"]
        
      elsif @params["type"] == "details"
        csv << ["Property Name", "Unit #", "Full Name", "Gender", "Birthday", "Household Status", "Occupation Type", "Minutes To Work", 
                "Transportation To Work", "# of Pets", "Pet Type", "Moved From", "# of Cars", "Annual Income", "Household Size", "Email"]
      end
      
      while query_count > 0
        limit = (current_page+1)*per_page
        skip = limit - per_page

        pp "query_count: #{query_count}, limit: #{limit}, skip: #{skip}"
        
        residents_listing(limit, skip).each do |r|
          if @params["type"] == "emails"
            csv << [
              property_dict[r["properties"]["property_id"]],
              [r["first_name"], r["last_name"]].join(" "),
              unit_dict[r["properties"]["unit_id"]],
              r["street"],
              r["city"],
              r["state"],
              r["zip"],
              r["properties"]["status"],
              r["email"],
              (r["properties"]["move_in"].strftime("%m/%d/%Y") rescue nil)
            ]
            
          elsif @params["type"] == "birthday"
            csv << [
              property_dict[r["properties"]["property_id"]],
              [r["first_name"], r["last_name"]].join(" "),
              r["email"],
              r["street"],
              r["city"],
              r["state"],
              r["zip"],
              (r["birthday"].strftime("%m/%d/%Y") rescue nil),
              age(r["birthday"])
            ]
            
          elsif @params["type"] == "details"
            csv << [
              property_dict[r["properties"]["property_id"]],
              unit_dict[r["properties"]["unit_id"]],
              [r["first_name"], r["last_name"]].join(" "),
              r["gender"],
              (r["birthday"].strftime("%m/%d/%Y") rescue nil),
              r["properties"]["household_status"],
              r["properties"]["occupation_type"],
              r["properties"]["minutes_to_work"],
              r["properties"]["transportation_to_work"],
              r["properties"]["pets_count"],
              r["properties"]["pet_type"],
              r["properties"]["moving_from"],
              r["properties"]["vehicles_count"],
              r["properties"]["annual_income"],
              r["properties"]["household_size"],
              r["email"]
              
            ]
          end
        end

        query_count-=per_page
        current_page+=1
      end
    end
  
    return csv_string, file_name
  end

  def self.perform(page_id, params)
    begin
      csv_string, file_name = init(Property.find(page_id), params).generate_csv
    
      file_name = "#{MultiTenant.generate_id}_#{file_name}"

      File.open("#{TMP_DIR}#{file_name}", "wb") { |f| f.write(csv_string) }
    
      ::Notifier.system_message("Resident Data",
        "Your file was exported successfully.
        <br><br> 
        <a href='http://#{HOST}/downloads/#{file_name}'>Download File</a> 
        <br><br> To protect your data the download link will work for the next two hours, or until you download the file
        <br>
        <br>
        CRM Team
        <br>
        help@hy.ly", @params["recipient"], {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now

      Resque.enqueue_at(Time.now + 2.hours, DownloadCleaner, file_name)
    
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      ::Notifier.system_message("[ResidentExporter] FAILURE", "ERROR DETAILS: #{error_details}",
        ::Notifier::DEV_ADDRESS, {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now
      
      ::Notifier.system_message("Resident Data",
        "There was an error while exporting your data, please contact help@hy.ly for help",
        @params["recipient"], {"from" => ::Notifier::EXIM_ADDRESS}).deliver_now
    end
  end
  
end