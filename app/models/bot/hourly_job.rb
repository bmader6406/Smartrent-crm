class HourlyJob
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY

  def self.queue
    :crm_scheduled
  end

  def self.perform(time = Time.now.utc)
    time = Time.parse(time) if time.kind_of?(String)
    time = time.in_time_zone('Eastern Time (US & Canada)')

    #TODO: store the below job in database when it is executed
    # time, class, arguments
    
    Resque.enqueue(MetricGenerator, time.to_i)

    if time.hour == 0
      Resque.enqueue(Smartrent::DailyResidentCreator, time)
      Resque.enqueue(ResidentPropertyStatusChanger, time)
    end

    #Just to make sure that this task runs before the monthly status updater
    #So we'll execute this at the end of the week
    #And if in any case the end of the week turns out to be first day of the month, we'll execute it on the previous day
    
    day_to_execute = time.end_of_week.day
    if day_to_execute == 1
      day_to_execute = time.end_of_month.day
    end
    if time.day == day_to_execute && time.hour == 0
      Resque.enqueue(Smartrent::WeeklyPropertyXmlImporter, time)
      Resque.enqueue(UnitLoadWorker, time)
      Resque.enqueue(UnitRefreshWorker, time)
    end

    if time.day == 1 && time.hour == 0 #execute at the begining of month
      Resque.enqueue(Smartrent::MonthlyStatusUpdater, time.prev_month)

      # wait for MonthlyStatusUpdater executed
      Resque.enqueue_at(time + 2.hours, Smartrent::ResidentExporter, time.prev_month)

      #- app.hy.ly import should be run at midnight ET + 4hours
      #- email should be scheduled around 7AM ET
    end

  end
end
