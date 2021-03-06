require 'csv'

class ResidentImporter
  def self.queue
    :crm_import
  end

  def self.perform(file_path, type = "yardi", resident_map = {}, meta = {})
    if type == "yardi"
      yardi_import(file_path, resident_map, meta)
      
    elsif type == "non_yardi"
      non_yardi_import(file_path, resident_map, meta)
      
    elsif type == "non_yardi_master"
      non_yardi_master_import(file_path, resident_map, meta)

    end
  end

  def self.yardi_logger
    @@yardi_logger ||= Logger.new("/mnt/exim-data/task_log/yardi_#{Date.today}.log")
  end

  def self.non_yardi_logger
    @@non_yardi_logger ||= Logger.new("/mnt/exim-data/task_log/non-yardi_#{Date.today}.log")
  end
  
  def self.yardi_import(file_path, resident_map, meta)
    # 0"Elan ID",1"Property ID",2"Property Name",3"First Name",4"Last Name",5"Email Address",
    #6"Move-in Date",7"Move-out Date",8"Tenant Status",9"Unit #",10"Tenant Code"
    log_output = "/mnt/exim-data/task_log/yardi_importer_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"

    yardi_logger.info("Resident Importer started for Date: #{Date.today} -- Time: #{Time.now}")

    resident_list = []
  
    prop_map = {}

    Property.where("is_crm = 1 OR is_smartrent = 1").each do |p|
      p.yardi_property_id.to_s.split(";").each do |yid| #multiple id separated by ;
        next if yid.blank?
        if yid.include?("/")
          yid.split("/").each do |id|
            prop_map[id.strip.gsub(/^0*/, '')] = p.id.to_s
          end
        else
          prop_map[yid.strip.gsub(/^0*/, '')] = p.id.to_s
        end
      end
    end
    
    pp ">>>> prop_map: ", prop_map
    
    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end

    index, new_resident, existing_resident, errs = 0, 0, 0, []
    ok_row = 0
    
    File.foreach(file_path) do |line|
      index += 1
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if row.join.blank?

          property_id = prop_map[row[ resident_map["yardi_property_id"] ].to_s.strip.gsub(/^0*/, '') ]
          pp property_id

          next if !property_id
          next if check_resident_fullname(row[resident_map["first_name"]] + row[resident_map["last_name"]])
          pp "success"
          yardi_logger.info("PropertyID: #{property_id} -- Resident: #{row[resident_map['first_name']] + row[resident_map['last_name']]}" )
          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          row[ resident_map["tenant_code"] ]= row[ resident_map["tenant_code"] ].to_s.strip
          unit_code = row[ resident_map["unit_code"] ].to_s.strip
          email = row[ resident_map["email"] ].to_s.strip
          # email = safe_email(row[ resident_map["email"] ].to_s.strip)

          # Some residents have this email format:
          #- Allie.donovan@hotmail.co.uk; alex.donovan@hilton.com
          #- KatCzeck21@hotmail.com, kspedden2005@yahoo.com
          #- Burt0096@UMN,edu
          #- Christian.Motsebo@yahoo,com
          
          # TODO: check if we should cleanup the email or keep yardi data as is
          email = email_clean(email)

          #temporary fix
          email_list = ["lmerchan@revolutionmessaging.com", "lmm42689@gmail.com"]
          email = email_list[1] if email == email_list[0]
          row[ resident_map["email"] ] = email if email == email_list[0]
          
          email_lc = email.to_s.downcase
          fake_email = nil
          
          #convert blank and ignored email into fake email
          if email.blank? || !email.include?("@") || convert_fake_email?(email_lc)
            fake_email = "#{tenant_code}@noemail.yardi"
              email = fake_email # don't not unify fake email or non-existant email
              email_lc = email
          end

          yardi_logger.info("Resident Email : #{email_lc} Email in CSV  : #{row[ resident_map["email"] ]}")
          
          ok_row += 1
          # UnitLoader use the mits4_1.xml, this file contains unit details
          # Yardi import should create the unit if the unit details is not populated (aka UnitLoader has not run yet)
          unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
          unit.save(:validate => false)

          yardi_logger.info("Unit Updated : Property: #{property_id} -- Unit ID: #{unit.id} -- Unit Code: #{unit_code}")
          
          pp "#{ok_row}/#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

          # consolidate resident by tenant_code if email is changed in feed
          # Name and other details can also be changed. Currently only email change exists
          residents_with_tenant_code = Resident.with(:consistency => :strong).where({ units: { '$elemMatch' => {tenant_code: tenant_code, property_id: property_id} } }).unify_ordered
          yardi_logger.info("Residents exist for tenant_code #{tenant_code}")
          yardi_logger.info("Residents count with email: #{residents_with_tenant_code.count} #{residents_with_tenant_code.collect(&:email_lc)}")
          residents_with_tenant_code.each do |r|
            if r && r.email_lc != email_lc
              resident = r
              pre_email = resident.email_lc.to_s.strip
              new_email_exist = Resident.with(:consistency => :strong).where(:email => pre_email).first
              if new_email_exist
                pp "delete the unit #{unit_code} from this resident"
                CSV.open(log_output, "a+") do |l|
                  l << ["Unit Transfer","from",pre_email,"to",email_lc,"unit_code",unit_code,"time",Time.now]
                  yardi_logger.info("Unit destroyed #{r.email_lc} -- tenant_code: #{tenant_code}")
                  r.units.where(:tenant_code => tenant_code).first.destroy
                  if r.units.count == 0 
                    yardi_logger.info("Resident destroyed #{r.email_lc}")
                    r.destroy 
                    l << ["Email Updated","from",pre_email,"to",email_lc,"unit_code",unit_code,"time",Time.now]
                  else
                    sr = Smartrent::Resident.find_by_email r.email
                    #If a smartrent resident_property is removed there is a chance of rewards getting error
                    # sr.resident_properties.first.reset_rewards_table if sr
                  end
                end
              end
            end
          end
          #consolidate resident by email if no resident with that tenant code exists
          resident = Resident.with(:consistency => :strong).where(:email_lc => email_lc ).unify_ordered.first if !resident
          pp ">>> email_lc: #{email_lc}, resident_id: #{resident ? resident.id : ""}, unit_id: #{unit ? unit.id : ""}"
          
          resident = Resident.new if !resident
          new_record = resident.new_record?
          
          create_or_update = true
          not_update_resident = false
          
          # build attrs from csv file (we will delete the data that we don't want to override below)
          Resident::CORE_FIELDS.each do |f|
            f = f.to_s # must convert f to string
            if resident_map[f]
              if ["email"].include?(f)
                resident.email = email # email can be real or fake email
              elsif ["last_name"].include?(f)
                 resident.last_name = row[resident_map[f]]
              elsif ["first_name"].include?(f)
                 resident.first_name = row[resident_map[f]]
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
          
          if fake_email || email.to_s.include?("@noemail") #mark as bad
            resident.email_check = "Bad"
            resident.email_checked_at = Time.now
            resident.subscribed = false
          end
        
          # don't use symbol as hash key
          unit_attrs = {
            "property_id" => property_id,
            "roommate" => tenant_code.to_s.match(/^r/) ? true : false
          }

          Resident::UNIT_FIELDS.each do |f|
            f = f.to_s # must f convert to string
            unit_attrs[f] = row[resident_map[f]] if resident_map[f]  && !row[resident_map[f]].blank?

            #pp "property field: #{f}, #{unit_attrs[f]}"

            if ["signing_date", "move_in", "move_out"].include?(f) && unit_attrs[f]
              unit_attrs[f] = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
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
                resident.activities.where(:property_id => unit_attrs["property_id"], :unit_id => unit_attrs["unit_id"]).delete_all
                
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
                  if !["property_id", "unit_id", "roommate", "status", "move_in", "move_out", "tenant_code"].include?(k)
                    unit_attrs.delete(k)
                  end
                end
                
              else
                # the system will create a new resident unit
              end
              
            end
            
          end
          
          if create_or_update
            yardi_logger.info("Update/create resident")
            if not_update_resident || resident.save # if not_update_resident is true, resident.save will NOT be called
              yardi_logger.info("Updated / Created")
              resident.sources.create(unit_attrs) if unit_attrs["property_id"]
            
              if new_record
                yardi_logger.info("New Resident Created : #{resident.email}")
                new_resident += 1
              else
                yardi_logger.info("Resident Updated : #{resident.email}")
                existing_resident += 1
              end
              
            else
              errs << ["#{index}, #{tenant_code}, #{email}, " + resident.errors.full_messages.join(", ")]
            end
          end
          resident_list << resident.id
        end #/csv parse

      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        pp ">>> line: #{line}, ERROR:", error_details
      end

    end

    #change status of all resident units not present in the yardi csv to past
    # change_status_to_past(resident_list.uniq)
    
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
    
    
    # for missing tenancy alert (only incremental_upload has this check)
    prop_tenant_code_dict = {}
    total_missing = 0
    
    # temporary turn off Import Alert because of thre Future Resident may not exist in the new feed
    # https://www.dropbox.com/s/05dlal31phg1uz9/Screenshot%202016-03-16%2023.35.07.png?dl=0
    # possible solutions:
    # - get a list of the residents that was created via CRM
    # - compare with yardi feed
    # -- if CRM's resident does not exist in yardi file => create an alert
    
    if meta["incremental_upload"] && false
      File.foreach(file_path.gsub("_diff.csv", ".csv")) do |line|
        index += 1
        begin
          CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
            next if row.join.blank?

            property_id = prop_map[row[ resident_map["yardi_property_id"] ].to_s.strip.gsub(/^0*/, '') ]

            next if !property_id

            tenant_code = row[ resident_map["tenant_code"] ].to_s.strip

            if prop_tenant_code_dict[property_id]
              prop_tenant_code_dict[property_id] << tenant_code
            else
              prop_tenant_code_dict[property_id] = [tenant_code]
            end

          end #/csv parse
        rescue Exception => e
          error_details = "#{e.class}: #{e}"
          error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
          pp ">>> line: #{line}, ERROR:", error_details
        end
      end
      
      pp "prop_tenant_code_dict.keys", prop_tenant_code_dict.keys
      
      prop_tenant_code_dict.keys.each do |property_id|
        pp ">>> property_id: #{property_id}"
        Resident.where("units.property_id" => property_id).each do |r|
          r.units.each do |u|
            next if u.property_id != property_id
            next if u.tenant_code.blank?

            if !prop_tenant_code_dict[property_id].include?( u.tenant_code ) #not exist on yardi side
              pp ">>> missing: #{total_missing}, property_id: #{property_id}, u.tenant_code: #{u.tenant_code}"
              total_missing += 1
              unit_code = Unit.find(u.unit_id).code rescue nil
              alert = ImportAlert.create(:property_id => property_id, :unit_code => unit_code, :tenant_code => u.tenant_code, :email => r.email)

              Notification.create({
                :property_id => property_id,
                :resident_id => r.id,
                :unit_id => u.unit_id,
                :import_alert_id => alert.id,
                :state => "pending",
                :subject => "Yardi Import",
                :message => alert.message
              })

            end
          end
        end
      end
      
    end
    
    # run the monthly status to correct the status of the immediate status, this task will not create any rewards
    # Resque.enqueue_at(Time.now + 12.hours, Smartrent::MonthlyStatusUpdater, Time.now.prev_month, false, Time.now - 1.day)
    
    Notifier.system_message("#{}[CRM] Yardi Importing Success",
      email_body(new_resident, existing_resident, total_missing, errs.length, file_name),
      recipient, {"from" => OPS_EMAIL, "filename" => errFile, "csv_string" => errCSV}).deliver_now

    
    pp ">>>", email_body(new_resident, existing_resident, total_missing, errs.length, file_name)
  end
  
  # obsolete
  def self.non_yardi_import(file_path, resident_map, meta)
    prop_map = {}

    meta["property_map"].keys.each do |prop_id|
      meta["property_map"][prop_id].to_s.split(";").each do |nyid| #multiple id separated by ;
        next if nyid.blank?
        prop_map[nyid.strip.gsub(/^0*/, '')] = prop_id.to_s
      end
    end

    pp ">>>> prop_map: ", prop_map

    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end
    
    pp ">>>>> resident_map", resident_map
    
    index, new_resident, existing_resident, errs = 0, 0, 0, []
    ok_row = 0

    pp ">>>>> file_path: #{file_path}"
    
    File.foreach(file_path) do |line|
      index += 1
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if index == 1 && row.detect{|c| ["Property Name", "PropertyName", "Property ID", "Property ID", "Move In Date", "MoveInDate"].include?(c) }
          next if row.join.blank?
          
          property_id = prop_map[row[ resident_map["non_yardi_property_id"] ].to_s.strip.gsub(/^0*/, '') ]
          
          pp "index: #{index}, property_id: #{property_id}"
          
          next if !property_id
          next if check_resident_fullname(row[resident_map["first_name"]].to_s + ' ' + row[resident_map["last_name"]].to_s)
          
          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          unit_code = row[ resident_map["unit_code"] ].to_s.strip
          email = row[ resident_map["email"] ].to_s.strip
          # email = safe_email(row[ resident_map["email"] ].to_s.strip)

          if tenant_code.blank?
            tenant_code = [
              row[ resident_map["first_name"] ].to_s.downcase.strip,
              row[ resident_map["last_name"] ].to_s.downcase.strip
            ].reject{|a| a.blank? }.join("-")
          end
          
          if unit_code.blank?
            unit_code = "temp-code"
          end

          email = email_clean(email)

          email_lc = email.to_s.downcase
          fake_email = nil

          #convert blank and ignored email into fake email
          if email.blank? || !email.include?("@") || convert_fake_email?(email_lc)
            fake_email = "#{tenant_code}@noemail.non-yardi"
            email = fake_email # don't not unify fake email or non-existant email
            email_lc = email
          end

          ok_row += 1
          # UnitLoader use the mits4_1.xml, this file contains unit details
          # Yardi import should create the unit if the unit details is not populated (aka UnitLoader has not run yet)
          unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
          unit.save(:validate => false)

          pp "#{ok_row}/#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

          #consolidate resident by email
          resident = Resident.with(:consistency => :strong).where(:email_lc => email_lc ).unify_ordered.first
          pp ">>> email_lc: #{email_lc}, resident_id: #{resident ? resident.id : ""}, unit_id: #{unit ? unit.id : ""}"

          resident = Resident.new if !resident
          new_record = resident.new_record?

          create_or_update = true
          not_update_resident = false

          # build attrs from csv file (we will delete the data that we don't want to override below)
          Resident::CORE_FIELDS.each do |f|
            f = f.to_s # must convert f to string
            if resident_map[f]
              if ["email"].include?(f)
                resident.email = email # email can be real or fake email
              else
                resident[f] = row[resident_map[f]]
              end
            end
          end

          if fake_email || email.to_s.include?("@noemail") #mark as bad
            resident.email_check = "Bad"
            resident.email_checked_at = Time.now
            resident.subscribed = false
          end

          # don't use symbol as hash key
          unit_attrs = {
            "property_id" => property_id,
            "roommate" => tenant_code.to_s.match(/^r/) ? true : false
          }

          Resident::UNIT_FIELDS.each do |f|
            f = f.to_s # must f convert to string
            unit_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?

            #pp "property field: #{f}, #{unit_attrs[f]}"

            if ["signing_date", "move_in", "move_out"].include?(f) && unit_attrs[f]
              date = Date.strptime(unit_attrs[f], '%Y%m%d') rescue nil
              
              if !date
                date = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
              end
              
              unit_attrs[f] = date
            end

            if ["unit_id"].include?(f)
              unit_attrs[f] = unit.id.to_s
            end
          end

          if !new_record # record exists
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

          end

          #pp ">>> before saving:", resident.attributes

          if create_or_update
            if not_update_resident || resident.save # if not_update_resident is true, resident.save will NOT be called
              resident.sources.create(unit_attrs) if unit_attrs["property_id"]

              if new_record
                new_resident += 1
              else
                existing_resident += 1
              end

            else
              errs << ["#{index}, #{tenant_code}, #{email}, " + resident.errors.full_messages.join(", ")]
            end
          end
        end #/csv parse

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
    ImportLog.find(meta["import_log_id"]).update_attributes(:stats => {
      :new_resident => new_resident,
      :existing_resident => existing_resident,
      :total_missing => total_missing,
      :errors_count => errs.length
    })

    # run the monthly status to correct the status of the immediate status, this task will not create any rewards
    Resque.enqueue_at(Time.now + 12.hours, Smartrent::MonthlyStatusUpdater, Time.now.prev_month, false, Time.now - 1.day)

    Notifier.system_message("[CRM] Non-Yardi Importing Success",
      email_body(new_resident, existing_resident, total_missing, errs.length, file_name),
      recipient, {"from" => OPS_EMAIL, "filename" => errFile, "csv_string" => errCSV}).deliver_now


    pp ">>>", email_body(new_resident, existing_resident, total_missing, errs.length, file_name)
  end
  
  def self.non_yardi_master_import(file_path, resident_map, meta)
    
    prop_map = {}

    log_output = "/mnt/exim-data/task_log/non_yardi_master_importer_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"

    non_yardi_logger.info("Resident Importer started for Date: #{Date.today} -- Time: #{Time.now}")

    resident_list = []

    Property.where("is_crm = 1 OR is_smartrent = 1").each do |p|
      p.elan_property_id.to_s.split(";").each do |eid| #multiple id separated by ;
        next if eid.blank?
        if eid.include?("/")
          eid.split("/").each do |id|
            prop_map[id.strip.gsub(/^0*/, '')] = p.id.to_s
          end
        else
          prop_map[eid.strip.gsub(/^0*/, '')] = p.id.to_s
        end
      end
    end
    # Property.where("is_crm = 1 OR is_smartrent = 1").each do |p|
    #   next if p.elan_number.blank?
    #   prop_map[p.elan_number.to_s] = p.id.to_s
    # end

    pp ">>>> prop_map: ", prop_map

    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end
    
    index, new_resident, existing_resident, errs = 0, 0, 0, []
    ok_row = 0

    pp ">>>>> file_path: #{file_path}"
    
    File.foreach(file_path) do |line|
      index += 1
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if index == 1 && row.detect{|c| ["Property Name", "PropertyName", "Property ID", "Property ID", "Move In Date", "MoveInDate", "Move-in Date"].include?(c) }
          next if row.join.blank?
          
          elan_number = row[ resident_map["elan_number"] ].to_s.strip
          property_id = prop_map[elan_number]
          pp "index: #{index}, property_id: #{property_id}, elan_number: #{elan_number}"
          
          next if !property_id

          next if check_resident_fullname(row[resident_map["first_name"]].to_s + ' ' +row[resident_map["last_name"]].to_s)

          non_yardi_logger.info("PropertyID: #{property_id} -- Resident: #{row[resident_map['first_name']] + row[resident_map['last_name']]}" )

          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          row[ resident_map["tenant_code"] ]= row[ resident_map["tenant_code"] ].to_s.strip

          unit_code = row[ resident_map["unit_code"] ].to_s.strip
          email = row[ resident_map["email"] ].to_s.strip
          # email = safe_email(row[ resident_map["email"] ].to_s.strip)
          
          if tenant_code.blank?
            tenant_code = [
              row[ resident_map["first_name"] ].to_s.downcase.strip,
              row[ resident_map["last_name"] ].to_s.downcase.strip
            ].reject{|a| a.blank? }.join("-")
          end
          
          if unit_code.blank?
            unit_code = "temp-code"
          end

          email = email_clean(email)
          email_lc = email.to_s.downcase
          fake_email = nil

          #convert blank and ignored email into fake email
          if email.blank? || !email.include?("@") || convert_fake_email?(email_lc)
            fake_email = "#{tenant_code}@noemail.non-yardi"
            email = fake_email # don't not unify fake email or non-existant email
            email_lc = email
          end

          non_yardi_logger.info("Resident Email : #{email_lc} Email in CSV  : #{row[ resident_map["email"] ]}")

          ok_row += 1
          # UnitLoader use the mits4_1.xml, this file contains unit details
          # Yardi import should create the unit if the unit details is not populated (aka UnitLoader has not run yet)
          unit = Unit.find_or_initialize_by(property_id: property_id, code: unit_code)
          unit.save(:validate => false)

          non_yardi_logger.info("Unit Updated : Property: #{property_id} -- Unit ID: #{unit.id} -- Unit Code: #{unit_code}")

          pp "#{ok_row}/#{index}, property id: #{property_id}, email: #{email}, unit code: #{unit_code}"

          #consolidate resident by email
          residents_with_tenant_code = Resident.with(:consistency => :strong).where({ units: { '$elemMatch' => {tenant_code: tenant_code, property_id: property_id} } }).unify_ordered
          non_yardi_logger.info("Residents exist for tenant_code #{tenant_code}")
          non_yardi_logger.info("Residents count with email: #{residents_with_tenant_code.count} #{residents_with_tenant_code.collect(&:email_lc)}")

          residents_with_tenant_code.each do |r|    
            if r && r.email_lc != email_lc    
              resident = r    
              pre_email = resident.email_lc.to_s.strip
              new_email_exist = Resident.with(:consistency => :strong).where(:email => pre_email).first   
              if new_email_exist    
                pp "delete the unit #{unit_code} from this resident"    
                CSV.open(log_output, "a+") do |l|   
                  l << ["Unit Transfer","from",pre_email,"to",email_lc,"unit_code",unit_code,"time",Time.now]   
                  non_yardi_logger.info("Unit destroyed #{r.email_lc} -- tenant_code: #{tenant_code}")
                  r.units.where(:tenant_code => tenant_code).first.destroy    
                  if r.units.count == 0   
                    non_yardi_logger.info("Resident destroyed #{r.email_lc}") 
                    r.destroy     
                    l << ["Email Updated","from",pre_email,"to",email_lc,"unit_code",unit_code,"time",Time.now]   
                  else    
                    sr = Smartrent::Resident.find_by_email r.email    
                    #sr.resident_properties.first.reset_rewards_table if sr    
                  end   
                end   
              end   
            end   
          end

          resident = Resident.with(:consistency => :strong).where(:email_lc => email_lc ).unify_ordered.first
          pp ">>> email_lc: #{email_lc}, resident_id: #{resident ? resident.id : ""}, unit_id: #{unit ? unit.id : ""}"

          resident = Resident.new if !resident
          new_record = resident.new_record?

          create_or_update = true
          not_update_resident = false

          # build attrs from csv file (we will delete the data that we don't want to override below)
          Resident::CORE_FIELDS.each do |f|
            f = f.to_s # must convert f to string
            if resident_map[f]
              if ["email"].include?(f)
                resident.email = email # email can be real or fake email
              else
                resident[f] = row[resident_map[f]]
              end
            end
          end

          if fake_email || email.to_s.include?("@noemail") #mark as bad
            resident.email_check = "Bad"
            resident.email_checked_at = Time.now
            resident.subscribed = false
          end

          # don't use symbol as hash key
          unit_attrs = {
            "property_id" => property_id,
            "roommate" => tenant_code.to_s.match(/^r/) ? true : false
          }

          Resident::UNIT_FIELDS.each do |f|
            f = f.to_s # must f convert to string

            unit_attrs[f] = row[resident_map[f]] if resident_map[f] && !row[resident_map[f]].blank?
            # pp "property field: #{f}, #{unit_attrs[f]}"

            if ["signing_date", "move_in", "move_out"].include?(f) && unit_attrs[f]
              date = Date.strptime(unit_attrs[f], '%Y%m%d') rescue nil
              
              if !date
                date = Date.strptime(unit_attrs[f], '%m/%d/%Y') rescue nil
              end
              
              unit_attrs[f] = date
            end

            if ["unit_id"].include?(f)
              unit_attrs[f] = unit.id.to_s
            end
          end

          if !new_record # record exists
            existing_unit = resident.units.detect{|u| u.unit_id.to_s == unit.id.to_s }

            if existing_unit # update status, move in, move out only
              not_update_resident = true

              unit_attrs.keys.each do |k|
                if !["property_id", "unit_id", "roommate", "status", "move_in", "move_out", "tenant_code"].include?(k)
                  unit_attrs.delete(k)
                end
              end

            else
              # the system will create a new resident unit
            end

          end

          #pp ">>> before saving:", resident.attributes

          if create_or_update
            non_yardi_logger.info("Update/create resident")
            if not_update_resident || resident.save # if not_update_resident is true, resident.save will NOT be called
              non_yardi_logger.info("Updated / Created")
              resident.sources.create(unit_attrs) if unit_attrs["property_id"]

              if new_record
                non_yardi_logger.info("New Resident Created : #{resident.email}")
                new_resident += 1
              else
                non_yardi_logger.info("Resident Updated : #{resident.email}")
                existing_resident += 1
              end

            else
              errs << ["#{index}, #{tenant_code}, #{email}, " + resident.errors.full_messages.join(", ")]
            end
          end
        end #/csv parse

      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        pp ">>> line: #{line}, ERROR:", error_details
      end
    end

    #change status of all resident units not present in the non-yardi csv to past
    # change_status_to_past(resident_list.uniq)

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
    ImportLog.find(meta["import_log_id"]).update_attributes(:stats => {
      :new_resident => new_resident,
      :existing_resident => existing_resident,
      :total_missing => total_missing,
      :errors_count => errs.length
    })

    # run the monthly status to correct the status of the immediate status, this task will not create any rewards
    #Resque.enqueue_at(Time.now + 12.hours, Smartrent::MonthlyStatusUpdater, Time.now.prev_month, false, Time.now - 1.day)

    Notifier.system_message("[CRM] Non-Yardi-Master Importing Success",
      email_body(new_resident, existing_resident, total_missing, errs.length, file_name),
      recipient, {"from" => OPS_EMAIL, "filename" => errFile, "csv_string" => errCSV}).deliver_now


    pp ">>>", email_body(new_resident, existing_resident, total_missing, errs.length, file_name)
  end
  
  def self.convert_fake_email?(email_lc)
    return true if [" @", "noemail", "nomail", "notgiven", "didnotgive", "donothave", 
      "donotreply", "notgiven", "nonegiven", "noexist", "noreply",
      "@email.com", "@none.net", "@na.com", "@non.com", "efused@yahoo.com", "@test.com"
    ].any?{|e| email_lc.include?(e) }
    
    return true if ["na@", "no@", "non@", "none@", "unknown@", "no@", "test@"].any?{|e| email_lc.match(/^#{e}/) }
    return true if ["refuse", "refused", "decline", "declined"].any?{|e| email_lc.match(/^#{e}\d*@/) }
    return false
  end
  
  def self.email_body(new_resident, existing_resident, total_missing, error_resident, file_name)
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
- #{total_missing} #{total_missing != 1 ? "import alerts" : "import alert"} were created.

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

  def self.resident_text(count)
    count != 1 ? "residents" : "residents"
  end
  
  def self.safe_email(email)
    return email if email.blank?
    return email if Rails.env.production? || Rails.env.development?
    
    # stage, test will be converted
    # for e.g: johndoe@gmail.com will be changed to bozzuto_ops+johndoe_at_gmail.com@hy.ly
    
    return "admin+#{ email.gsub("@", "_at_") }@#{EMAIL_DOMAIN}"
  end

  def self.email_clean(email)
    if email.include?(";") && email.scan("@").length > 1 || email[-1] == ";"
      email = email.split(";").first.strip
    elsif email.include?(",") && email.scan("@").length > 1 || email[-1] == ","
      email = email.split(",").first.strip
    # elsif email.include?(",") && email.scan("@").length == 1
    #  email = email.gsub(",", ".").strip
    # elsif email.include?(" ")
    #  email = email.gsub(" ", "").strip
    end
    return email
  end

  def self.check_resident_fullname(fullname)
    full_name = fullname.gsub("-", "").upcase.strip
    return (full_name ==  "NONRES" or full_name.start_with?("NONRES ") or full_name.end_with?(" NONRES") or full_name.start_with?("NON RES") rescue false )
  end

  def self.change_status_to_past(resident_list)
    residents_status_to_past = Resident.where(:id.nin => resident_list)
    residents_status_to_past.each do |res|
      res.units.where(:status.nin => "Past").each do |unit|
        unit.status = "Past"
        unit.save
      end
    end
  end

end
