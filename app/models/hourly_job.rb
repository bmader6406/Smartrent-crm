class HourlyJob
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_test
  end
  
  def self.perform()
    puts "test"
  end
  
end
