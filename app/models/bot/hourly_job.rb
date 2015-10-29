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

    if time.wday == 0 && time.hour == 0 #Sunday of the current week
      Resque.enqueue(Smartrent::WeeklyPropertyXmlImporter, time)
    end
    
    if time.hour == 3
      # run yardi import daily at 3AM
      Import.where(:type => "load_yardi_daily", :active => true).each do |import|
        Resque.enqueue(YardiLoader, time, import.type)
      end
      
      if time.wday == 0 # run weekly at 3AM on Sunday
        Import.where(:type => "load_units_weekly", :active => true).each do |import|
          Resque.enqueue(UnitLoader, time, import.type)
        end
      end
    end

    if time.day == 1 && time.hour == 1 #execute at the begining of month
      Resque.enqueue(Smartrent::MonthlyStatusUpdater, time.prev_month)

      # wait for MonthlyStatusUpdater executed
      Resque.enqueue_at(time + 2.hours, Smartrent::ResidentExporter, time.prev_month)

      #- app.hy.ly import should be run at midnight ET + 4hours
      #- email should be scheduled around 7AM ET
    end

  end
end
