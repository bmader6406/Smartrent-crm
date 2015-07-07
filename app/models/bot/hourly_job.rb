class HourlyJob
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_routine
  end
  
  def self.perform(time = Time.now.utc)
    Resque.enqueue(VariationMetricGenerator, time.to_i)
    
    Resque.enqueue(SpamishEmailSent, time.to_i)
    
    Resque.enqueue(MetricGenerator, time.to_i)
  end
  
end
