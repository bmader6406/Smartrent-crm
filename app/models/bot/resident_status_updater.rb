require 'csv'
require 'net/ftp'

class ResidentStatusUpdater
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time = Date.today)
    time = Time.parse(time) if time.kind_of?(String)
    resident_list = {}

    begin
     
      import_yardi = Import.where(:type => "load_yardi_daily", :active => true).last
      tmp_yardi_file = file_download(time - 1.day, import_yardi)

      import_noyardi = Import.where(:type => "load_non_yardi_master_daily", :active => true).last
      tmp_noyardi_file = file_download(time -1.day, import_noyardi)

      resident_list = collect_resident_unit_list_from_yardi_file(tmp_yardi_file, {}, import_yardi.field_map)
      resident_list = collect_resident_unit_list_from_non_yardi_file(tmp_noyardi_file, resident_list, import_noyardi.field_map)

      File.open('/mnt/exim-data/task_log/resident_list.txt', 'w') {|f| f.write(resident_list) }

      pp "Total Resident present in CSVs(Yardi+NonYardi) : #{resident_list.count}."
      pp "Change resident status for those residents not present in CSV to Past."
      change_status_to_past(resident_list)
      pp "Change smartrent status for those residents whose all units are Past to Inactive."
      change_smartrent_status_to_inactive(resident_list.keys, time)
      pp "Update smartrent status for those residents whose expiry date is set less than today to Expired."
      update_smartrent_status(time)
      pp "Successfully completed status updation."
      message = "Total resident list from CSV: #{resident_list.count}. "
      Notifier.system_message("[CRM] ResidentStatusUpdater SUCCESS", "DETAILS: #{message}",
        ADMIN_EMAIL, {"from" => OPS_EMAIL}).deliver
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[CRM] ResidentStatusUpdater FAILURE", "ERROR DETAILS: #{error_details}",
        ADMIN_EMAIL, {"from" => OPS_EMAIL}).deliver
        
    end
  end

  def self.file_download(time, import)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]
    file_name = ftp_setting["file_name"].gsub("%Y%m%d", time.strftime("%Y%m%d"))
    tmp_file = "#{TMP_DIR}#{file_name.gsub("/", "_").gsub(".csv", "_#{Time.now.to_i}.csv")}"
    ftp_setting = import.ftp_setting
    Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
      ftp.passive = true
      ftp.getbinaryfile(file_name, tmp_file)
      puts "Ftp downloaded, #{file_name}, #{tmp_file}"
    end
    tmp_file
  end

  def self.collect_resident_unit_list_from_yardi_file(file_path, resident_list = {}, resident_map={})
    index = 0

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
    
    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end

    File.foreach(file_path) do |line|
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|

          next if row.join.blank?

          property_id = prop_map[row[ resident_map["yardi_property_id"] ].to_s.strip.gsub(/^0*/, '') ]
          next if !property_id

          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          if tenant_code.blank?
            tenant_code = [
              row[ resident_map["first_name"] ].to_s.downcase.strip,
              row[ resident_map["last_name"] ].to_s.downcase.strip
            ].reject{|a| a.blank? }.join("-")
          end

          unit_code = row[ resident_map["unit_code"] ].to_s.strip
          if unit_code.blank?
            unit_code = "temp-code"
          end

          unit = Unit.where(property_id: property_id, code: unit_code).last

          email = row[ resident_map["email"] ].to_s.strip
          email = email_clean(email)
          email_lc = email.to_s.downcase

          fake_email = nil
          
          #convert blank and ignored email into fake email
          if email.blank? || !email.include?("@") || convert_fake_email?(email_lc)
            fake_email = "#{tenant_code}@noemail.yardi"
              email = fake_email # don't not unify fake email or non-existant email
              email_lc = email
          end

          resident = Resident.with(:consistency => :strong).where(:email_lc => email_lc ).unify_ordered.first

          if resident and unit
            if resident_list.has_key?(resident.id) 
              resident_list[resident.id] <<  unit.id
            else
              resident_list[resident.id] = [unit.id]
            end
            resident_list[resident.id] = resident_list[resident.id].flatten
          end
        end
      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        pp ">>> line: #{line}, ERROR:", error_details
      end
    end
    resident_list
  end

  def self.collect_resident_unit_list_from_non_yardi_file(file_path, resident_list = {}, resident_map={})
    index = 0

    prop_map = {}

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

    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end

    File.foreach(file_path) do |line|
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if row.join.blank?

          elan_number = row[ resident_map["elan_number"] ].to_s.strip
          property_id = prop_map[elan_number]

          next if !property_id

          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          if tenant_code.blank?
            tenant_code = [
              row[ resident_map["first_name"] ].to_s.downcase.strip,
              row[ resident_map["last_name"] ].to_s.downcase.strip
            ].reject{|a| a.blank? }.join("-")
          end

          unit_code = row[ resident_map["unit_code"] ].to_s.strip

          if unit_code.blank?
            unit_code = "temp-code"
          end

          unit = Unit.where(property_id: property_id, code: unit_code)

          email = row[ resident_map["email"] ].to_s.strip
          email = email_clean(email)
          email_lc = email.to_s.downcase

          fake_email = nil

          #convert blank and ignored email into fake email
          if email.blank? || !email.include?("@") || convert_fake_email?(email_lc)
            fake_email = "#{tenant_code}@noemail.non-yardi"
            email = fake_email # don't not unify fake email or non-existant email
            email_lc = email
          end

          resident = Resident.with(:consistency => :strong).where(:email_lc => email_lc ).unify_ordered.first

          if resident and unit.count > 0
            if resident_list.has_key?(resident.id) 
              resident_list[resident.id] <<  unit.all.collect(&:id)
            else
              resident_list[resident.id] = unit.all.collect(&:id)
            end
            resident_list[resident.id] = resident_list[resident.id].flatten
          end
        end
      rescue Exception => e
        error_details = "#{e.class}: #{e}"
        error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
        pp ">>> line: #{line}, ERROR:", error_details
      end
    end
    resident_list
  end

  def self.email_clean(email)
    if email.include?(";") && email.scan("@").length > 1 || email[-1] == ";"
      email = email.split(";").first.strip
    elsif email.include?(",") && email.scan("@").length > 1 || email[-1] == ","
      email = email.split(",").first.strip
    end
    email
  end

  def self.change_status_to_past(resident_list)
    CSV.open("/mnt/exim-data/task_log/change_status_to_past_#{Time.now}.csv", "w") do |csv|
      resident_list.each do |key, val|
        res = Resident.where(_id: key).last
        res.units.where(:unit_id.nin => val).each do |unit|
          if unit.status != "Past"
            csv << [res.email, unit.unit_id]
            unit.set(status: "Past")
            unit.save
          end
        end
      end
      residents_status_to_past = Resident.where(:id.nin => resident_list.keys)
      residents_status_to_past.each do |res|
        res.units.each do |unit|
          if unit.status != "Past"
            csv << [res.email, unit.unit_id]
            unit.set(status: "Past")
            unit.save
          end
        end
      end
    end
  end

  def self.change_smartrent_status_to_inactive(resident_list, time)
    residents_status_to_inactive = Resident.where(:id.nin => resident_list)
    CSV.open('/mnt/exim-data/task_log/change_smartrent_status_to_inactive.csv', "w") do |csv|
      residents_status_to_inactive.each do |r|
        sr = Smartrent::Resident.find_by_crm_resident_id r.id
        if sr and sr.smartrent_status == Smartrent::Resident::STATUS_ACTIVE
          csv << [sr.email]
          sr.smartrent_status = Smartrent::Resident::STATUS_INACTIVE
          sr.expiry_date = time + 2.years
          sr.save
        end
      end
    end
  end

  def self.update_smartrent_status(time)
    Smartrent::Resident.includes(:resident_properties).all.each do |sr|
      sr.resident_properties.where('status IN (?)', [Smartrent::ResidentProperty::STATUS_CURRENT, Smartrent::ResidentProperty::STATUS_NOTICE] ).each do |rp|
        if rp.property.is_smartrent == true and sr.smartrent_status != Smartrent::Resident::STATUS_ACTIVE
          sr.smartrent_status = Smartrent::Resident::STATUS_ACTIVE
          sr.expiry_date = nil
          sr.save
          break
        end
      end
      if sr.expiry_date and sr.expiry_date.beginning_of_day <= time.beginning_of_day and sr.smartrent_status != Smartrent::Resident::STATUS_EXPIRED
        sr.smartrent_status = Smartrent::Resident::STATUS_EXPIRED
        sr.save
      end
    end
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

end
