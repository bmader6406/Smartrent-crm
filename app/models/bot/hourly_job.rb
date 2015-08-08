class HourlyJob
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_routine
  end
  
  def self.perform(time = Time.now.utc)
    
    time = time.in_time_zone('Eastern Time (US & Canada)')
    
    Resque.enqueue(MetricGenerator, time.to_i)
    
    if time.hour = 0
      Resque.enqueue(Smartrent::DailyResidentCreator, Time.now)
      Resque.enqueue(ResidentPropertyStatusChanger, Time.now)
    end
      
    if time.day == 1 && time.hour == 0 #execute at the begining of month
      Resque.enqueue(Smartrent::MonthlyStatusUpdater, Time.now.prev_month)
      
      # wait for MonthlyStatusUpdater executed
      Resque.enqueue_at(Time.now + 2.hours, Smartrent::ResidentExporter, Time.now.prev_month)
      
      #- app.hy.ly import should be run at midnight ET + 4hours
      #- email should be scheduled around 7AM ET
    end
    
  end
  
end
