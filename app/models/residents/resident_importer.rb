# # Import Yardi CSV file
# https://app.asana.com/0/376484593635/62561912450046/f

require 'csv'

class ResidentImporter
  def self.queue
    :crm_immediate
  end

  #TODO: create and set unit_id
  def self.perform(file_path, type = "yardi", resident_map = {}, meta = {})

    if type == "yardi"
      
      # Yardi file format
      # 0   Property Code
      # 1   Unit Code
      # 2   Tenant Code
      # 3   Tenant Name
      # 4   Tenant Address 1
      # 5   Tenant Address 2
      # 6   City
      # 7   State
      # 8   Zip Code
      # 9   Unit Status
      # 10  Email
      # 11  Move In
      # 12  Move Out
      # 13  Household Size
      # 14  Pets
      # 15  Rent
      # 16  Lead Type
      # 17  Gender
      # 18  Birthday
      # 19  Last 4 digits of Social Security Number
      # 20  Household Size
      # 21  Household Status
      # 22  Previous Residence (Address1, Address2, City, State, ZIP)
      # 23  Moving From
      # 24  Pets Count
      # 25  Pet Type
      # 26  Pet Breed
      # 27  Occupation Type
      # 28  Employer
      # 29  Employer City
      # 30  Employer State
      # 31  Annual Income
      # 32  Minutes to Work
      # 33  Transportation to Work
      # 34  License Plate 1
      # 35  Number of Vehicles
      
      prop_map = {}

      Property.where(:is_crm => 1).each do |p|
        prop_map[p.yardi_property_id.to_s.gsub(/^0*/, '')] = p.id
      end
      
      resident_map.keys.each do |k|
        resident_map[k] = resident_map[k].to_i # for array access
      end
      
      prop_unit_code_map = {}

      index, new_resident, existing_resident, errs = 0, 0, 0, []

      File.foreach(file_path) do |line|
        index += 1

        begin
          CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
            next if index == 1 || row.join.blank?

            property_id = prop_map[row[ resident_map["yardi_property_id"] ].to_s.gsub(/^0*/, '') ]

            next if !property_id

            tenant_code = row[ resident_map["tenant_code"] ]
            unit_code = row[ resident_map["unit_code"] ]
            email = row[ resident_map["email"] ]
            
            next if email.blank?
            
            # UnitLoader use the mits4_1.xml, this file contains unit details
            # Yardi import should create the unit if the unit details is not populated (aka UnitLoader has not run yet)
            unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
            unit.save(:validate => false)
            
            pp "#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

            #consolidate resident by email
            resident = Resident.with(:consistency => :strong).where(:email_lc => email.to_s.downcase ).unify_ordered.first
            pp ">>> email_lc: #{email.to_s.downcase}, resident_id: #{resident ? resident.id : ""}, unit_id: #{unit ? unit.id : ""}"
            
            resident = Resident.new if !resident
            new_record = resident.new_record?
            
            # full and incremental upload behave the same
            create_or_update = true
            not_update_resident = false
            
            # build attrs from csv file (we will delete the data that we don't wnat to override below)
            Resident::CORE_FIELDS.each do |f|
              f = f.to_s # must f convert to string
              if resident_map[f]
                if ["full_name"].include?(f)
                  resident.full_name = row[resident_map[f]]
                else
                  resident[f] = row[resident_map[f]]
                end

                if ["birthday"].include?(f)
                  resident[f] = Date.strptime(row[resident_map[f]], '%m/%d/%Y') rescue nil
                
                  if !resident[f]
                    resident[f] = Date.parse(row[resident_map[f]]) rescue nil
                  end
                end
              end
            end
          
            # don't use symboy as hash key
            unit_attrs = {
              "property_id" => property_id,
              "roommate" => tenant_code.to_s.match(/^r/) ? true : false
            }

            Resident::UNIT_FIELDS.each do |f|
              f = f.to_s # must f convert to string
              unit_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?

              #pp "property field: #{f}, #{unit_attrs[f]}"

              if ["signing_date", "move_in", "move_out"].include?(f) && unit_attrs[f]
                unit_attrs[f] = Date.strptime(unit_attrs[f], '%Y%m%d') rescue nil
              end

              if ["unit_id"].include?(f)
                unit_attrs[f] = unit.id.to_s
              end
            end
            
            if !new_record # record exists
              if meta["full_upload"]
                existing_unit = resident.units.detect{|u| u.unit_id.to_s == unit.id.to_s }
                
                if existing_unit 
                  # clear existing history for the current property
                  deleted_time = Time.now.utc
                  resident.activities.where(unit_attrs["property_id"], :unit_id => unit_attrs["unit_id"]).delete_all
                  
                  Comment.where(:resident_id => resident.id, :property_id => unit_attrs["property_id"], :unit_id => unit_attrs["unit_id"]).update_all(:deleted_at => deleted_time)
                  Ticket.where(:resident_id => resident.id, :property_id => unit_attrs["property_id"], :unit_id => unit_attrs["unit_id"]).update_all(:deleted_at => deleted_time)
                  Notification.where(:resident_id => resident.id, :property_id => unit_attrs["property_id"], :unit_id => unit_attrs["unit_id"]).update_all(:deleted_at => deleted_time)
                  
                  create_or_update = false # don't override existing data
                else
                  # the system will create a new resident unit
                end
                
              elsif meta["incremental_upload"]
                existing_unit = resident.units.detect{|u| u.unit_id.to_s == unit.id.to_s }
                
                if existing_unit # update status, move in, move out only
                  not_update_resident = true
                  
                  unit_attrs.keys.each do |k|
                    if !["property_id", "unit_id", "roommate", "status", "move_in", "move_out"].include?(k)
                      unit_attrs.delete(k)
                    end
                  end
                  
                else
                  # the system will create a new resident unit
                end
                
                # for missing tenancy alert
                missing = {
                  "unit_code" => unit_code
                  "tenant_code" => tennat_code,
                  "email" => email
                }
                if prop_unit_code_map[property_id]
                  prop_unit_code_map[property_id] << missing
                else
                  prop_unit_code_map[property_id] = [unit_code]
                end
                
              end
              
            end
            
            #pp ">>> before saving:", resident.attributes
            
            if create_or_update
              if not_update_resident || resident.save # if not_update_resident is true, resident.save will NOT be called
                #create submit
                resident.sources.create(unit_attrs) if unit_attrs["property_id"]
              
                if new_record
                  new_resident += 1
                else
                  existing_resident += 1
                end
              else
                errs << [resident.errors.full_messages.join(", ")]
              end
              
            else # missing tenancy case, create alert message
              
            end # /if create_or_save

          end

        rescue Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          pp ">>> line: #{line}, ERROR:", error_details
        end
      end
      
      
      errFile = nil
      errCSV = nil
      file_name = meta["file_name"]
      recipient = meta["recipient"]

      if errs.length > 0
        errFile ="errors_#{file_name}"

        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row }
        end
        
        #pp "errs", errs
      end
      
      total_missing = 0
      prop_unit_code_map.keys.each do |property_id|
        unit_codes = prop_unit_code_map[property_id].collect{|hash| hash["unit_code"] }
        #Property.find(property_id).units.
      end
      
      Notifier.system_message("[CRM] Yardi Importing Success",
        email_body(new_resident, existing_resident, errs.length, file_name),
        recipient, {"from" => Notifier::EXIM_ADDRESS, "filename" => errFile, "csv_string" => errCSV}).deliver_now

      pp ">>>", email_body(new_resident, existing_resident, errs.length, file_name)

    elsif type == "smartrent"
      resident_map = {
       "property_name" => 0,
       "unit_code" => 2,
       "full_name" => 1,
       "street" => 3,
       "city" => 4,
       "state" => 5,
       "zip" => 6,
       "email" => 7,
       "move_in" => 8
      }

      custom_name = {
        "The Beacon at Waugh Chapel" => "Beacon at Waugh Chapel",
        "Concord Park At Russett" => "Concord Park at Russett- Invesco",
        "The Courts of Devon" => "Courts of Devon JV 333204",
        "Creekstone Village Apartments" => "Creekstone Apartments",
        "The Glen Apartments" => "Glen Apartment",
        "The Gramercy at Town Center" => "Gramercy at Town Center",
        "The Apartments at Harbor Park" => "Harbor Park",
        "Hidden Creek Apartment Homes" => "Hidden Creek",
        "The Jefferson at Fair Oaks " => "Jefferson at Fair Oaks",
        "The Lexington at Market Square" => "Lexington- Phase 2",
        "MetroPointe" => "MetroPointe Tax",
        "The Metropolitan " => "Metropolitan - Tax Credit",
        "Monroe Street Market" => "Monroe Street Market-Portland Flats",
        "The Apartments at North Point " => "North Point Apartments",
        "Pinnacle Town Center " => "Pinnacle at Town Center",
        "The Promenade at Harbor East" => "Promenade at Harbor East- Residential",
        "Stone Point Apartments" => "Stone Point",
        "Strathmore Court at White Flint" => "Strathmore Court- Tax Credit",
        "The Fitzgerald at UB Midtown " => "The Fitzgerald",
        "Winthrop " => "The Winthrop",
        "The Townes at Harvest View " => "Townes at Harvest View",
        "Union Wharf Apartments" => "Union Wharf",
        "The Whitney " => "Whitney Apartments"
       }

      prop_map = {}

      Property.where(:is_smartrent => 1).each do |p|
        prop_map[ custom_name[p.name] || p.name] = p.id
      end

      index = 0

      File.foreach(file_path) do |line|
        index += 1

        begin
          CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
            next if index <= 2 || row.join.blank?

            property_id = prop_map[row[ resident_map["property_name"] ].to_s.gsub(/^0*/, '') ]

            next if !property_id

            unit_code = row[ resident_map["unit_code"] ]
            email = row[ resident_map["email"] ]

            next if email.blank?

            unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
            unit.save(:validate => false)

            pp "#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

            #consolidate resident by email
            resident = Resident.with(:consistency => :strong).where(:email_lc => email.to_s.downcase ).unify_ordered.first
            resident = Resident.new if !resident

            Resident::CORE_FIELDS.each do |f|
              f = f.to_s # must f convert to string
              if resident_map[f]
                if ["full_name"].include?(f)
                  resident.full_name = row[resident_map[f]]
                else
                  resident[f] = row[resident_map[f]]
                end
              end
            end
            
            # don't use symboy as hash key
            unit_attrs = {
              "property_id" => property_id
            }

            Resident::UNIT_FIELDS.each do |f|
              f = f.to_s
              unit_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?

              #pp "property field: #{f}, #{unit_attrs[f]}"

              if ["move_in"].include?(f) && unit_attrs[f]
                unit_attrs[f] = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
              end

              if ["unit_id"].include?(f) && unit
                pp "UNIT: #{unit}, #{f}"
                unit_attrs[f] = unit.id
              end
            end

            if resident.save
              #create submit
              resident.sources.create(unit_attrs) if unit_attrs["property_id"]
            end

          end

        rescue Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          pp ">>> line: #{line}, ERROR:", error_details
        end
      end
    end
    
  end

  def self.email_body(new_resident, existing_resident, error_resident, file_name)
    new_and_existing_resident = new_resident + existing_resident

    return <<-MESSAGE
Your file has been loaded:
<br>
- #{new_and_existing_resident} #{resident_text(new_and_existing_resident)} were imported successfully.
<br>
- #{new_resident} of #{new_and_existing_resident} imported #{resident_text(new_and_existing_resident)} were added to the residents list.
<br>
- #{existing_resident} of #{new_and_existing_resident} imported #{resident_text(new_and_existing_resident)} replaced existing residents.
<br>
- #{error_resident} #{resident_text(error_resident)} were not imported.

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

  def self.resident_text(count)
    count != 1 ? "residents" : "residents"
  end
end
