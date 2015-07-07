class DownloadCleaner
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_immediate
  end
  
  def self.perform(file_name)
    file_name = File.basename(file_name) #don't trust the user input
    
    path = "#{TMP_DIR}#{file_name}"
    File.delete(path) if File.exist?(path)
  end
  
end
