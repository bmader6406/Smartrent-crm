# Import BozzutoLink CSV file

require 'csv'

class PropertyImporter
  def self.queue
    :crm_immediate
  end
  
  def self.perform(file_path)
    user = User.unscoped.order('created_at asc').first

    prop_map = {
     "origin_id"=> 1,
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

    index = 0

    File.foreach(file_path) do |line|
      index += 1

      CSV.parse(line) do |row|
        next if index == 1
        
        origin_id = row[ prop_map["origin_id"] ].to_i
        property_name = row[ prop_map["name"] ]
        
        # bozzuto property no may be blank, it contains the leading zeros
        if origin_id > 0
          prop = Property.find_by(:origin_id => origin_id)
        else
          prop = Property.find_by(:name => property_name)
        end

        if !prop
          prop = Property.new
          
          # default to false for ALL flags (it is only has effect if this is a new property)
          # - manual turn is_crm on/off
          # - smartrent property import will change the is_smartrent/is_visible
          prop.is_crm = false
          prop.is_smartrent = false
          prop.is_visible = false
        end

        prop.user_id = user.id

        prop_map.keys.each do |k|
          val = row[ prop_map[k] ]

          if !val.blank?
            if k == "region_id"
              region = Region.find_or_create_by(:name => val)
              val = region.id
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