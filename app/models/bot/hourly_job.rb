class HourlyJob
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_routine
  end
  
  def self.perform(time = Time.now.utc)
    Resque.enqueue(MetricGenerator, time.to_i)
    
    Resque.enqueue(Smartrent::MonthlyStatusUpdater) if time.day == 1 && time.hour == 0 #execute at the begining of month
  end
  
end
