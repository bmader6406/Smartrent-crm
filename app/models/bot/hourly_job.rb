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
    puts ("Hourly Job started >>>>>")
      
    if time.hour == 0
      Resque.enqueue(ResidentUnitStatusChecker, time)
    end
    
    if time.hour == 3
      # BozzutoLink upload CSV feed at 3 AM
      # Resque.enqueue(PropertyImporter)

            # XML import at 2 AM
      Import.where(:type => "load_xml_property_importer", :active => true).each do |import|
        Resque.enqueue(XmlPropertyImporter, time, import.id)
      end
      
    end
    
    if time.hour == 3
      # run yardi import daily at 3AM
      Import.where(:type => "load_yardi_daily", :active => true).each do |import|
        Resque.enqueue(YardiLoader, time, import.id)
      end
      
      Import.where(:type => "load_non_yardi_master_daily", :active => true).each do |import|
        Resque.enqueue(NonYardiMasterLoader, time, import.id)
      end
      
      # disabled on 2017-Jan-20
      # Import.where(:type => "load_non_yardi_daily", :active => true).each do |import|
      #   Resque.enqueue(NonYardiLoader, time, import.id)
      # end
      # 
      if time.wday == 0 # run weekly at 3AM on Sunday
        Import.where(:type => "load_units_weekly", :active => true).each do |import|
          Resque.enqueue(UnitLoader, time, import.id)
        end
      end
    end

    if time.hour == 7
      Resque.enqueue(ResidentStatusUpdater)
    end

    # hourly job smartrent engine
    Smartrent::HourlyJob.perform(time)

  end
end
