require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")


class UnitLoader
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time, import_id);
    time = Time.parse(time) if time.kind_of?(String)
    import = Import.find(import_id)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]
    
    #Floorplan contains all the floor_plans
    unit_map = {
      :origin_id => ["Units", "UnitID"],
      :bed => ["Units","UnitBedrooms"],
      :bath => ["Units","UnitBathrooms"],
      :sq_ft => ["Units","MaxSquareFeet"],
      :rental_type => ["Units", "UnitEconomicStatus"],
      :code => ["Units", "MarketingName"]
    }
    property_map = {
      :name => ["PropertyID","MarketingName"],
      :origin_id => ["IDValue"]
    }
    
    begin
      file_name = ftp_setting["file_name"]
      tmp_file = "#{TMP_DIR}#{file_name.gsub("/", "_").gsub(".csv", "_#{Time.now.to_i}.csv")}"
      
      Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile(file_name, tmp_file)
        puts "Ftp downloaded"
      end
      
      index, new_unit, existing_unit, errs = 0, 0, 0, []
      
      properties = Hash.from_xml( File.read(tmp_file) )
    
      properties["PhysicalProperty"]["Property"].each_with_index do |p, pndx|
        name = p.nest(property_map[:name])
        property_origin_id = p.nest(property_map[:origin_id])
        property = Smartrent::Property.where("lower(name) = ? or origin_id=?", name.downcase, property_origin_id).first
      
        p["ILS_Unit"].each_with_index do |u, undx|
          origin_id = u.nest(unit_map[:origin_id])
          code = u.nest(unit_map[:code])
          pp "pndx: #{pndx + 1}, undx: #{undx +1 }, origin_id: #{origin_id}"
        
          next if !origin_id.present?
        
          # if unit's code exist, update it. 
          # Otherwise create new unit
          
          # don't use origin_id, it will end up with duplicate Unit code for a specific property
          # for example: 44892, 538 vs 53136, 538
          #unit = Unit.where(:property_id => property.id, :origin_id => origin_id).first
          
          # Check Yardi's unit (which may first created by the ResidentImporter)
          unit = Unit.where(:property_id => property.id, :code => code).first 
          unit = Unit.new if !unit
          unit.property_id = property.id if property
        
          new_record = unit.new_record?
        
          ActiveRecord::Base.transaction do
            unit_map.each do |key, value|
              unit[key] = u.nest(value)
            end
          
            unit.updated_by = "xml_feed"
            unit.status = "Active"
          
            if unit.save
              pp ">>>>>>>>> #{new_record ? "Unit has been created" : "Unit has been updated"}", unit.attributes
              
              if new_record
                new_unit += 1
              else
                existing_unit += 1
              end
            else
              errs << unit.errors.full_messages.join(", ")
            end
          end  
        
        end
      end #/ properties loop
      
      errFile = nil
      errCSV = nil

      if errs.length > 0
        errFile ="errors_#{file_name}"
      
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
      end
      
      Notifier.system_message("[CRM] Units Importing Success",
        email_body(new_unit, existing_unit, errs.length, file_name),
        recipient, {"from" => Notifier::EXIM_ADDRESS, "filename" => errFile, "csv_string" => errCSV}).deliver
    
      pp ">>>", email_body(new_unit, existing_unit, errs.length, file_name)
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"
        
    end
  end

  def self.email_body(new_unit, existing_unit, error_unit, file_name)
    new_and_existing_unit = new_unit + existing_unit

    return <<-MESSAGE
Your file has been loaded:
<br>
- #{new_and_existing_unit} #{unit_text(new_and_existing_unit)} were imported successfully.
<br>
- #{new_unit} of #{new_and_existing_unit} imported #{unit_text(new_and_existing_unit)} were added to the units list.
<br>
- #{existing_unit} of #{new_and_existing_unit} imported #{unit_text(new_and_existing_unit)} replaced existing units.
<br>
- #{error_unit} #{unit_text(error_unit)} were not imported.

<br> 
- Source: #{file_name}.
<br>
<br>
<br>
CRM Help Team
<br>
help@hy.ly

    MESSAGE
  end

  def self.unit_text(count)
    count != 1 ? "units" : "units"
  end
  
end
