# Import BozzutoLink CSV file

require 'csv'

class PropertyImporter
  def self.queue
    :crm_immediate
  end
  
  def self.perform(file_path)
    # Property.all.each do |prop|
    #   prop.state = prop.state.upcase if prop.state
    #   prop.city = prop.city.titleize if prop.city
    #   prop.county = prop.county.titleize if prop.county
    #   prop.save
    # end

    ###

    user = User.first

    prop_map = {
     "name"=> 2,
     "address_line1"=> 5,
     "city"=> 6,
     "state"=> 7,
     "zip"=> 8,
     "county" => 11,
     "email"=> 36,
     "phone"=> 12,
     "webpage_url"=>49,
     "website_url"=> 16,
     "status"=> 60,
     "svp"=> 53,
     "region_id" => 10,
     "property_number"=> 1,
     "l2l_property_id"=> 18,
     "yardi_property_id"=> 20,
     "owner_group"=> 14,
     "date_opened"=> 3,
     "date_closed"=> 4,
     "monday_open_time" => 21,
     "monday_close_time" => 22,
     "tuesday_open_time" => 23,
     "tuesday_close_time" => 24,
     "wednesday_open_time" => 25,
     "wednesday_close_time" => 26,
     "thursday_open_time" => 27,
     "thursday_close_time" => 28,
     "friday_open_time" => 29,
     "friday_close_time" => 30,
     "saturday_open_time" => 31,
     "saturday_close_time" => 32,
     "sunday_open_time" => 33,
     "sunday_close_time" => 34
    }

    # date close, # date open
    # AM, PM open closed

    region_map = {}

    Region.all.each do |r|
      region_map[r.name] = r.id
    end

    index = 0

    File.foreach(file_path) do |line|
      index += 1

      CSV.parse(line) do |row|
        next if index == 1

        property_name = row[ prop_map["name"] ]
        region_name = row[ prop_map["region_id"] ]
        prop = Property.find_by_name(property_name)

        if !prop
          prop = Property.new
          prop.is_crm = true
          prop.is_smartrent = false
        end

        prop.user_id = user.id

        prop_map.keys.each do |k|
          val = row[ prop_map[k] ]

          if !val.blank?
            if k == "region_id"
              val = region_map[val]
            end

            if k.match(/^date_/)
              val = Date.parse(val) rescue nil
            end

            if k.match(/open_time$/)
              if val.to_i >= 12
                val = "#{val} PM"
              elsif val.to_i > 0
                val = "#{val} AM"
              end
              
            elsif k.match(/close_time$/) #close time always in PM
              val = "#{val} PM"
            end

            prop[k] = val
          end
        end

        prop.save

      end
    end
  end
  
end