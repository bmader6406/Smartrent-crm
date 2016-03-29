require 'csv'
require 'net/ftp'

class NonYardiLoader
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_immediate
  end

  def self.perform(time, import_id);
    time = Time.parse(time) if time.kind_of?(String)
    time = time - 1.day # yardi file is 1 day behind
    import = Import.find(import_id)
    ftp_setting = import.ftp_setting
    recipient = ftp_setting["recipient"]

    begin
      paths = []
      ordered_paths = {}
      import_count = 0
      
      ftp = Net::FTP.new()
      ftp.passive = true
      ftp.connect(ftp_setting["host"])
      ftp.login(ftp_setting["username"], ftp_setting["password"])
      
      #recursive scan for .csv file
      scan(ftp, ftp_setting["path"].strip, paths)
      
      paths.each do |path|
        mtime = ftp.mtime(path)
        if mtime + 60.days < Time.now #delete 60 days old files
          ftp.delete(path)
        else
          ordered_paths["#{mtime.to_i}_#{path}"] = path
        end
      end
      
      #order mtime asc and import files
      ordered_paths.keys.sort{|a, b| a <=> b}.each do |k|
        sleep(rand(5)+2)
        path = ordered_paths[k]
        
        if import.logs.where(:import_id => import.id, :file_path => path).first
          # pp "File #{path} already imported"
          # next
        end
        
        log = import.logs.create(:file_path => path)
        
        #download daily file
        file_name = File.basename(path)
        tmp_file = "#{TMP_DIR}#{file_name.gsub(".csv", "_#{Time.now.to_i}.csv")}"
        ftp.getbinaryfile(path, tmp_file)
        
        meta = { "file_name" => file_name, "recipient" => recipient, "property_map" => import.property_map, "import_log_id" => log.id }

        Resque.enqueue(ResidentImporter, tmp_file, "non_yardi", import.field_map, meta)
      end
      
    rescue Exception => e
      error_details = "#{e.class}: #{e}"
      error_details += "\n#{e.backtrace.join("\n")}" if e.backtrace
      p "ERROR: #{error_details}"

      Notifier.system_message("[CRM] NonYardiLoader FAILURE", "ERROR DETAILS: #{error_details}",
        recipient, {"from" => Notifier::EXIM_ADDRESS}).deliver
        
    end
  end
  
  def self.scan(ftp, dir, paths)
    ftp.chdir(dir)
    entries = ftp.list('*')
    entries.each do |entry|
      if entry.split(/\s+/)[0][0,1] == "d" then
        scan(ftp, entry.split.last, paths)
      else
        if entry.split.last.to_s.downcase.include?(".csv")
          paths << "#{ftp.pwd}/#{entry.split.last}"
        end
      end
    end
    # Since we dipped down a level to scan this directory, lets go back to the parent so we can scan the next directory.
    ftp.chdir('..')
  end
  
end
