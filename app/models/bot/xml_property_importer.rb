require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")


class XmlPropertyImporter
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time, import_id)
    begin
    time = Time.parse(time) if time.kind_of?(String)
    import = Import.find(import_id)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]
    property_map = import.field_map
    property_map ||= {
      :origin_id => ["IDValue"],
      :name => ["PropertyID","MarketingName"],
      :address_line1 => ["PropertyID","Address","AddressLine1"],
      :city => ["PropertyID","Address","City"],
      :state => ["PropertyID","Address","State"],
      :zip => ["PropertyID","Address","PostalCode"],
      :county => ["PropertyID","Address","CountyName"],
      :email => ["PropertyID","Email"],
      :phone => ["PropertyID","Phone","PhoneNumber"],
      :website_url => ["PropertyID","WebSite"],
      :info => ["Information","OfficeHour"],
      :description => ["Information","LongDescription"],
      :latitude => ["ILS_Identification","Latitude"],
      :longitude =>  ["ILS_Identification","Longitude"],
      :floor_plans => ["Floorplan"],
      :features => ["Amenity"]
    }

    floor_plans_map = {
      :name => ["Name"],
      :origin_id => ["IDValue"],
      :url => ["FloorplanAvailabilityURL"],
      :beds => ["Bedrooms"],
      :baths =>["Bathrooms"] ,
      :sq_feet_max => ["SquareFeet", "Max"],
      :sq_feet_min => ["SquareFeet", "Min"],
      :rent_min => ["EffectiveRent", "Min"],
      :rent_max => ["EffectiveRent", "Max"]
    }

    features_map = {
      :name => ["GeneralAmenityType"]
    }

    Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
      ftp.passive = true
      ftp.getbinaryfile("mits4_1.xml","#{TMP_DIR}mits4_1.xml")
    end

    tmp_file = File.read("#{TMP_DIR}mits4_1.xml")
    index, new_prop, existing_prop, errs = 0, 0, 0, []
    properties = Hash.from_xml(tmp_file) 
    properties["PhysicalProperty"]["Property"].each_with_index do |p, pndx|
      name = p.nest(property_map[:name])
      property_origin_id = p.nest(property_map[:origin_id])

      property = Smartrent::Property.where("origin_id=?",property_origin_id).first
      property ||= Smartrent::Property.where("REPLACE(REPLACE(LOWER(name),' ',''),'-','')=?",name.downcase.gsub(/[^a-z0-9\w]/i,'')).first

      if !property
        new_prop = new_prop + 1
        property = Smartrent::Property.new 
        property.is_smartrent = false
        property.is_crm = false
        property.is_visible = true
        property.updated_by = "mits4_xml_feed"
        property.smartrent_status = Smartrent::Property::STATUS_CURRENT
        property.origin_id = property_origin_id
        property.property_number = property_origin_id
        property.name = name.titleize
        region = Region.find_by(:name => property_map[:county])
        if region
          property.region_id = region.id
        end
      else
        existing_prop = existing_prop + 1        
      end

      information = p.nest(property_map[:info])
      if !information.nil?
      information.each do |infomsg|
          case infomsg["Day"] # a_variable is the variable we want to compare
          when "Monday"   #compare to 1
            property.monday_open_time = infomsg["OpenTime"] 
            property.monday_close_time = infomsg["CloseTime"] 
          when "Tuesday"    #compare to 2
            property.tuesday_open_time = infomsg["OpenTime"] 
            property.tuesday_close_time = infomsg["CloseTime"]
          when "Wednesday"    #compare to 2
            property.wednesday_open_time = infomsg["OpenTime"] 
            property.wednesday_close_time = infomsg["CloseTime"] 
          when "Thursday"    #compare to 2
            property.thursday_open_time = infomsg["OpenTime"] 
            property.thursday_close_time = infomsg["CloseTime"] 
          when "Friday"   #compare to 1
            property.friday_open_time = infomsg["OpenTime"] 
            property.friday_close_time = infomsg["CloseTime"] 
          when "Saturday"    #compare to 2
            property.saturday_open_time = infomsg["OpenTime"] 
            property.saturday_close_time = infomsg["CloseTime"] 
          when "Sunday"    #compare to 2
            property.sunday_open_time = infomsg["OpenTime"] 
            property.sunday_close_time = infomsg["CloseTime"] 
          else
          end
        end
      end

        property.address_line1 = p.nest(property_map[:address_line1])
        property.city = p.nest(property_map[:city])
        property.state = p.nest(property_map[:state])
        property.zip = p.nest(property_map[:zip])
        property.county = p.nest(property_map[:county])
        property.email = p.nest(property_map[:email])
        property.phone = p.nest(property_map[:phone])
        property.website_url = p.nest(property_map[:website_url])
        property.description = p.nest(property_map[:description])
        property.latitude = p.nest(property_map[:latitude])
        property.longitude = p.nest(property_map[:longitude])


        # Get list of amenities from the XML
        property_features = []
        features = p.nest(property_map[:features])
        if features.present?
          if features.kind_of?(Hash) 
            features = [features]
          end
          features.each do |feature|
            feature_hash = {}
            features_map.each do |feature_key, feature_value|
              feature_hash[feature_key]
              if feature.nest(feature_value).present?
                feature_hash[feature_key] = feature.nest(feature_value).strip
              end
            end
            if feature_hash.present?
              property_features << feature_hash
            end
          end
        end

        # Get Floor plans from the XML
        property_floor_plans = []
        floor_plans = p.nest(property_map[:floor_plans])
        if floor_plans.present?
          if floor_plans.kind_of?(Hash) 
            floor_plans = [floor_plans] #push hash to array
          end
          floor_plans.each do |fp|
            floor_plan = {}
            roomtypes_list = []
            roomtypes_list = fp["Room"].collect{|x| [x["RoomType"], x["Count"]]}.to_h
            floor_plans_map.each do |floor_key, floor_value|
              floor_plan[floor_key]
              if fp.nest(floor_value).present?
                floor_plan[floor_key] = fp.nest(floor_value).strip
              else
                floor_plan[floor_key] = fp.nest(floor_value)
              end
            end
            floor_plan[:beds] = roomtypes_list[floor_plans_map[:beds].first]
            floor_plan[:baths] =  roomtypes_list[floor_plans_map[:baths].first]
            property_floor_plans << floor_plan
          end
        end
        # Save property
        if property.save

          # save all features 
          feature_ids = []
          property_features.each do |feature|   
            feature_name =  feature[:name].downcase.gsub(/[^a-z0-9\w]/i,'')        
            s_feature =  Smartrent::Feature.where("REPLACE(REPLACE(LOWER(name),' ',''),'-','')=?",feature_name).first
            s_feature ||= property.features.create(feature)
            s=property.property_features.find_or_create_by(:feature_id => s_feature.id)
            feature_ids << s_feature.id
          end 

          # Save Floor plans
          floor_plan_ids = []
          property_floor_plans.each do |floor_plan|
            fp = Smartrent::FloorPlan.where(:property_id => property.id, :origin_id => floor_plan[:origin_id]).first
            if fp
              fp.update_attributes(floor_plan)
            else
              fp = property.floor_plans.create(floor_plan)
            end
            floor_plan_ids << fp.id
          end

      #delete previous floor plans to use the new floorplans from the xml
      floor_plan_ids = floor_plan_ids.uniq
      Smartrent::FloorPlan.where("property_id = ? AND id NOT IN (?)", property.id, floor_plan_ids).delete_all

      #delete previous features to use the new features from the xml except Smartrent
      smartrent_id = Smartrent::Feature.where("LOWER(name)=?","smartrent").last.id
      if smartrent_id
        feature_ids << smartrent_id
      end
      Smartrent::PropertyFeature.where("property_id = ? AND feature_id NOT IN (?)", property.id, feature_ids).delete_all
    end
  end


  errFile = nil  
  errCSV = nil
  file_name = ftp_setting["file_name"].gsub("%Y%m%d", time.strftime("%Y%m%d"))
  recipient = ftp_setting["recipient"]
  if errs.length > 0
    errFile ="errors_#{file_name}"
    errCSV = CSV.generate do |csv|
      errs.each {|row| csv << row}
    end
  end

  # for logging only
  log = import.logs.create(:file_path => file_name)
  pp email_body(new_prop, existing_prop, errs.length, file_name)
  Notifier.system_message("[CRM] Property Importing Success",email_body(new_prop, existing_prop, errs.length, file_name), recipient).deliver_now
  # Notifier.system_message("[CRM] Property Importing Success",email_body(new_prop, existing_prop, errs.length, file_name),
  #   recipient, {"from" => OPS_EMAIL, "filename" => errFile, "csv_string" => errCSV}).deliver
  rescue  Exception => e
    recipient = ftp_setting["recipient"]
    error_details = "#{e.class}: #{e}"
    error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
    p "ERROR: #{error_details}"
    p "[CRM] Property Importing  - FAILURE"
    Notifier.system_message("[XmlPropertyImporter] FAILURE", "ERROR DETAILS: #{error_details}", recipient).deliver_now
  end
end


def self.email_body(new_prop, existing_prop, error_prop, file_name)
  new_and_existing_prop = new_prop + existing_prop

  return <<-MESSAGE
  Property Import from XML is successful.
  <br>
  - #{new_and_existing_prop} #{prop_text(new_and_existing_prop)} were imported successfully.
  <br>
  - #{new_prop} of #{new_and_existing_prop} imported #{prop_text(new_and_existing_prop)} were added to the properties list.
  <br>
  - #{existing_prop} of #{new_and_existing_prop} imported #{prop_text(new_and_existing_prop)} updated existing properties.
  <br>
  - #{error_prop} #{prop_text(error_prop)} were not imported.

  <br> 
  - Source: #{file_name}.
  <br>
  <br>
  <br>
  CRM Help Team
  <br>
  #{HELP_EMAIL}

  MESSAGE
end

def self.prop_text(count)
  count != 1 ? "property" : "properties"
end

end
