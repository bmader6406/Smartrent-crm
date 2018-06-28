require 'csv'
require 'net/ftp'

class ResidentStatusUpdater
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time = Time.now)
    time = Time.parse(time) if time.kind_of?(String)
    time = time.in_time_zone('Eastern Time (US & Canada)')
    resident_list = {}

    begin
     
      import_yardi = Import.where(:type => "load_yardi_daily", :active => true).last
      # tmp_yardi_file = file_download(time - 1.day, import_yardi)
      tmp_yardi_file = "/mnt/exim-data/_bozzuto_yardi_residents_YardiResidents-Full-20180624_1529940230.csv"

      import_noyardi = Import.where(:type => "load_non_yardi_master_daily", :active => true).last
      # tmp_noyardi_file = file_download(time -1.day, import_noyardi)
      tmp_noyardi_file = "/mnt/exim-data/_non_bozzuto_yardi_residents_noyardiresidents20180624_1529945999.csv"

      resident_list = collect_resident_unit_list_from_file(tmp_yardi_file, {}, import_yardi.field_map)
      resident_list = collect_resident_unit_list_from_file(tmp_noyardi_file, resident_list, import_noyardi.field_map)

      File.open('/mnt/exim-data/task_log/resident_list.txt', 'w') {|f| f.write(resident_list) }

      pp "resident_list #{resident_list.count}"
      pp "change_status_to_past"
      change_status_to_past(resident_list)
      pp "change_smartrent_status_to_inactive"
      change_smartrent_status_to_inactive(resident_list.keys, time)
      pp "update_smartrent_status"
      update_smartrent_status(time)
      pp "success"
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

  def self.collect_resident_unit_list_from_file(file_path, resident_list = {}, resident_map={})
    index = 0

    resident_map.keys.each do |k|
      resident_map[k] = resident_map[k].to_i # for array access
    end

    File.foreach(file_path) do |line|
      begin
        CSV.parse(line.gsub('"\",', '"",').gsub(' \",', ' ",').gsub('\"', '""')) do |row|
          next if row.join.blank?
          tenant_code = row[ resident_map["tenant_code"] ].to_s.strip
          email = row[ resident_map["email"] ].to_s.strip
          email = email_clean(email)
          email_lc = email.to_s.downcase
          resident = Resident.where(email_lc: email_lc).last
          if resident
            if resident_list.has_key?(resident.id) 
              resident_list[resident.id] <<  tenant_code
            else
              resident_list[resident.id] = [tenant_code]
            end
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
    CSV.open('/mnt/exim-data/task_log/change_status_to_past.csv', "w") do |csv|
      resident_list.each do |key, val|
        res = Resident.where(_id: key).last
        res.units.where(:tenant_code.nin => val).each do |unit|
          if unit.status != "Past"
            csv << [res.email, unit.tenant_code]
            unit.set(status: "Past")
            unit.save
          end
        end
      end
      residents_status_to_past = Resident.where(:id.nin => resident_list.keys)
      residents_status_to_past.each do |res|
        res.units.each do |unit|
          if unit.status != "Past"
            csv << [res.email, unit.tenant_code]
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
      sr.resident_properties.where(status: Smartrent::ResidentProperty::STATUS_CURRENT).each do |rp|
        if rp.property.is_smartrent == true and sr.smartrent_status != Smartrent::Resident::STATUS_ACTIVE
          sr.smartrent_status = Smartrent::Resident::STATUS_ACTIVE
          sr.expiry_date = nil
          sr.save
          break
        end
      end
      if sr.expiry_date and sr.expiry_date.beginning_of_day == time.beginning_of_day
        sr.smartrent_status = Smartrent::Resident::EXPIRED
        sr.save
      end

    end
  end

end
