require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")


class XmlUnitImporter
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time, import_id)
    puts "Ftp FTP FTP FTP "
    time = Time.parse(time) if time.kind_of?(String)
    import = Import.find(import_id)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]

    property_map = {
      :origin_id => ["IDValue"],
      :name => ["PropertyID","MarketingName"],
      :address_line1 => ["PropertyID","Address","AddressLine1"],
      :city => ["PropertyID","Address","City"],
      :state => ["PropertyID","Address","State"],
      :zip => ["PropertyID","Address","ZipCode"],
      :county => ["PropertyID","Address","CountyName"],
      :email => ["PropertyID","Email"],
      :phone => ["PropertyID","Phone","PhoneNumber"],
      :website_url => ["PropertyID","WebSite"],
      :info => ["Information","OfficeHour"]
    }
      # :elan_number => [],
      # :property_status => [], 
      # :webpage_url =>,
      # :status => [],
      # :svp => [],
      # :region_id => [],
      # :property_number => [],
      # :l2l_property_id => [],
      # :yardi_property_id => [],
      # :owner_group => [],
      # :date_opened => [],
      # :date_closed => [],
      # :monday_open_time => [Information, OfficeHour, ],
      # :monday_close_time => [],
      # :tuesday_open_time => [],
      # :tuesday_close_time => [],
      # :wednesday_open_time => [],
      # :wednesday_close_time => [],
      # :thursday_open_time => [],
      # :thursday_close_time => [],
      # :friday_open_time => [],
      # :friday_close_time => [],
      # :saturday_open_time => [],
      # :saturday_close_time => [],
      # :sunday_open_time => [],
      # :sunday_close_time => [],
      # :regional_manager => []



      Net::FTP.open('feeds.livebozzuto.com', 'CRMbozchh', 'NAQpPt41') do |ftp|
        ftp.passive = true
        ftp.getbinaryfile("mits4_1.xml","#{TMP_DIR}mits4_1.xml")
        puts "Ftp downloaded"
      end

      pp "#{TMP_DIR}mits4_1.xml"

      tmp_file = File.read("#{TMP_DIR}mits4_1.xml")

      index, new_prop, existing_prop, errs = 0, 0, 0, []
      properties = Hash.from_xml(tmp_file) 
      pp ">>>>>>>>>>>><<<<<<<<<<<<<"


      properties["PhysicalProperty"]["Property"].each_with_index do |p, pndx|
        name = p.nest(property_map[:name])
        property_origin_id = p.nest(property_map[:origin_id])

        pp ">>> pndx: #{pndx+1}: origin_id: #{property_origin_id}, name: #{name}"

        property = Smartrent::Property.where("lower(name) = ? or origin_id=?", name.downcase, property_origin_id).first

        if !property
          property = Smartrent::Property.new 
          property.is_smartrent = true
          property.is_crm = false
          property.updated_by = "mits4_xml_feed"
          property.smartrent_status = Smartrent::Property::STATUS_CURRENT
          property.origin_id=property_origin_id
          property.name=name.downcase
          region = Region.find_by(:name => property_map[:county])
          if region
            property.region_id = region.id
          end
          pp "Creating new property"
        end


        information = p.nest(property_map[:info])
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
            puts "it was something else"
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

        property.save

        pp ">>> Saved Property"
        pp property

        errFile = nil
        errCSV = nil

        if errs.length > 0
          errFile ="errors_#{file_name}"

          errCSV = CSV.generate do |csv|
            errs.each {|row| csv << row}
          end
        end


      # for logging only
      log = import.logs.create(:file_path => file_name)
      
      Notifier.system_message("[CRM] Prpperty Importing Success",
        email_body(new_prop, existing_prop, errs.length, file_name),
        recipient, {"from" => OPS_EMAIL, "filename" => errFile, "csv_string" => errCSV}).deliver

      pp ">>>", email_body(new_prop, existing_prop, errs.length, file_name)
      
    # rescue Exception => e
    #   error_details = "#{e.class}: #{e}"
    #   error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
    #   p "ERROR: #{error_details}"
  end
end

def self.email_body(new_prop, existing_prop, error_unit, file_name)
  new_and_existing_prop = new_prop + existing_prop

  return <<-MESSAGE
  Your file has been loaded:
  <br>
  - #{new_and_existing_prop} #{unit_text(new_and_existing_prop)} were imported successfully.
  <br>
  - #{new_prop} of #{new_and_existing_prop} imported #{unit_text(new_and_existing_prop)} were added to the units list.
  <br>
  - #{existing_prop} of #{new_and_existing_prop} imported #{unit_text(new_and_existing_prop)} replaced existing units.
  <br>
  - #{error_unit} #{unit_text(error_unit)} were not imported.

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

def self.unit_text(count)
  count != 1 ? "prop" : "props"
end

end
