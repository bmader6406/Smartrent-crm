require 'csv'
require 'net/ftp'

class YardiLoader
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time = nil, import_id);
    time = Time.parse(time) if time.kind_of?(String)
    time = time - 1.day # yardi file is 1 day behind
    import = Import.find(import_id)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]

    begin
      file_name = ftp_setting["file_name"].gsub("%Y%m%d", time.strftime("%Y%m%d"))
      tmp_file = "#{TMP_DIR}#{file_name.gsub("/", "_").gsub(".csv", "_#{Time.now.to_i}.csv")}"

      Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
        ftp.passive = true
        ftp.getbinaryfile(file_name, tmp_file)
        puts "Ftp downloaded, #{file_name}, #{tmp_file}"
      end
      
      meta = { "file_name" => file_name, "recipient" => recipient }
      
      if import.type == "load_yardi_daily"
        meta["incremental_upload"] = 1
        
        yesterday_file_name = ftp_setting["file_name"].gsub("%Y%m%d", time.yesterday.strftime("%Y%m%d"))
        yesterday_tmp_file = "#{TMP_DIR}#{file_name.gsub("/", "_").gsub(".csv", "_#{Time.now.to_i}.csv")}"
        
        Net::FTP.open(ftp_setting["host"], ftp_setting["username"], ftp_setting["password"]) do |ftp|
          ftp.passive = true
          ftp.getbinaryfile(yesterday_file_name, yesterday_tmp_file)
          puts "Ftp downloaded: #{yesterday_file_name}, #{yesterday_tmp_file}"
        end
        
        # create diff file
        #sort csv file
        #pp ">> tmp_file: #{tmp_file} #{Time.now.to_f}"
        system("sort #{tmp_file} -o #{tmp_file}")

        #pp ">> yesterday_tmp_file: #{yesterday_tmp_file} #{Time.now.to_f}"
        system("sort #{yesterday_tmp_file} -o #{yesterday_tmp_file}")
        
        csv_string = []
        sleep(2)
        Diffy::Diff.new(yesterday_tmp_file, tmp_file, :source => 'files', :context => 0).each do |line|
          if line =~ /^\+/
            csv_string << line.sub("+", "")
          end
        end

        csv_string.insert(0, "\n") # csv headers
        
        tmp_file = tmp_file.gsub(/\.csv/i, "_diff.csv")
        File.open(tmp_file, "wb") { |f| f.write(csv_string.join()) }
        
      elsif import.type == "load_yardi_one_time"
        meta["full_upload"] = 1
        
      end
      
      Resque.enqueue(ResidentImporter, tmp_file, "yardi", import.field_map, meta)
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[CRM] Yardi Importing FAILURE", "ERROR DETAILS: #{error_details}",
        recipient, {"from" => Notifier::EXIM_ADDRESS}).deliver
        
    end
  end
  
end
