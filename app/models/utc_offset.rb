class UtcOffset
  
  # metric is calculated at midnight of the user timezone, the record was saved in UTC timezone  
  # when retreive the metric.created_at value, rails auto +/- DST hour
  # the DST_HOUR = 3.hours is a hack to make the detect function work without worry about DST or not
  # page_metrics.detect {|pm| pm.created_at > (time  + UtcOffset::DST_HOUR ) && pm.created_at <= (time.end_of_day + UtcOffset::DST_HOUR ) }
    
  DST_HOUR = 3.hours 
    
  def self.friendly_identifier(utc_offset)
    { -11 => 'Samoa',
      -10 => 'Hawaii',
      -9 => 'Alaska',
      -8 => 'Pacific Time (US & Canada)',
      -7 => 'Mountain Time (US & Canada)',
      -6 => 'Central Time (US & Canada)',
      -5 => 'Eastern Time (US & Canada)',
      -4.5 => 'Caracas',
      -4 => 'Atlantic Time (Canada)',
      -3.5 => 'Newfoundland',
      -3 => 'Buenos Aires',
      -2 => 'Mid-Atlantic',
      -1 => 'Cape Verde Is.',
      0 => 'London',
      1 => 'Paris',
      2 => 'Cairo',
      3 => 'Moscow',
      3.5 => 'Tehran',
      4 => 'Baku',
      4.5 => 'Kabul',
      5 => 'Karachi',
      5.5 => 'Mumbai',
      5.75 => 'Kathmandu',
      6 => 'Dhaka',
      6.5 => 'Rangoon',
      7 => 'Jakarta',
      8 => 'Hong Kong',
      9 => 'Tokyo',
      9.5 => 'Adelaide',
      10 => 'Sydney',
      11 => 'Solomon Is.',
      12 => 'Auckland',
      13 => "Nuku'alofa"
    }[utc_offset]
  end
  
  def self.time_zones(utc_offset)
    utc_offset_and_zones[utc_offset] || []
  end
  
  def self.midnight_time_zones(h)
    time_zones(0 <= h && h <= 11 ? "-#{h}".to_i : 24 - h)
  end
  
  def self.midnight_in_time_zone(zone)
    midnight = Time.now.utc.midnight
    
    hsh = {}
    
    utc_offset_and_zones.keys.each do |offset|
      utc_offset_and_zones[offset].each do |zone|
        hsh[zone] = offset
      end
    end
    
    if hsh[zone].hour > 0
      midnight + 1.day - hsh[zone].hour
    else
      midnight - hsh[zone].hour
    end
  end
  
  private
  
    def self.utc_offset_and_zones
      @utc_offset_and_zones ||= { -11 => ['Samoa', 'International Date Line West', 'Midway Island'],
        -10 => ['Hawaii'],
        -9 => ['Alaska'],
        -8 => ['Pacific Time (US & Canada)', 'Tijuana'],
        -7 => ['Mountain Time (US & Canada)', 'Arizona', 'Chihuahua', 'Mazatlan'],
        -6 => ['Central Time (US & Canada)', 'Central America', 'Guadalajara', 'Mexico City', 'Monterrey', 'Saskatchewan'],
        -5 => ['Eastern Time (US & Canada)', 'Bogota', 'Indiana (East)', 'Lima', 'Quito', ''], #'' for user who has not set timezone
        #-4.5 => ['Caracas'], #move to bottom
        -4 => ['Atlantic Time (Canada)', 'La Paz', 'Santiago', 'Caracas'],
        #-3.5 => ['Newfoundland'],
        -3 => ['Buenos Aires', 'Brasilia', 'Georgetown', 'Greenland', 'Newfoundland'],
        -2 => ['Mid-Atlantic'],
        -1 => ['Cape Verde Is.',' Azores'],
        0 => ['London', 'Casablanca', 'Dublin', 'Edinburgh', 'Lisbon', 'Monrovia', 'UTC'],
        1 => ['Paris', 'Amsterdam', 'Belgrade', 'Berlin', 'Bern', 'Bratislava', 'Brussels', 'Budapest', 'Copenhagen', 'Ljubljana', 'Madrid', 
          'Prague', 'Rome', 'Sarajevo', 'Skopje', 'Stockholm', 'Vienna', 'Warsaw', 'West Central Africa', 'Zagreb'],
        2 => ['Cairo', 'Athens', 'Bucharest', 'Harare', 'Helsinki', 'Istanbul', 'Jerusalem', 'Kyiv', 'Minsk', 'Pretoria', 'Riga', 'Sofia', 'Tallinn', 'Vilnius'],
        3 => ['Moscow', 'Baghdad', 'Kuwait', 'Nairobi', 'Riyadh', 'St. Petersburg', 'Volgograd'],
        #3.5 => ['Tehran'],
        4 => ['Baku', 'Abu Dhabi', 'Muscat', 'Tbilisi', 'Yerevan', 'Tehran'],
        #4.5 => ['Kabul'],
        5 => ['Karachi', 'Ekaterinburg', 'Islamabad', 'Tashkent', 'Kabul'],
        #5.5 => ['Mumbai', 'Chennai', 'Kolkata', 'New Delhi', 'Sri Jayawardenepura'],
        #5.75 => ['Kathmandu'],
        6 => ['Dhaka', 'Almaty', 'Astana', 'Novosibirsk', 'Mumbai', 'Chennai', 'Kolkata', 'New Delhi', 'Sri Jayawardenepura', 'Kathmandu'],
        #6.5 => ['Rangoon'],
        7 => ['Jakarta', 'Bangkok', 'Hanoi', 'Krasnoyarsk', 'Rangoon'],
        8 => ['Hong Kong', 'Beijing', 'Chongqing',' Irkutsk', 'Kuala Lumpur', 'Perth', 'Singapore', 'Taipei', 'Ulaan Bataar', 'Urumqi'],
        9 => ['Tokyo', 'Osaka', 'Sapporo', 'Seoul', 'Yakutsk'],
        #9.5 => ['Adelaide', 'Darwin'],
        10 => ['Sydney', 'Brisbane', 'Canberra', 'Guam', 'Hobart', 'Melbourne', 'Port Moresby', 'Vladivostok', 'Adelaide', 'Darwin'],
        11 => ['Solomon Is.', 'Magadan', 'New Caledonia'],
        12 => ['Auckland', 'Fiji', 'Kamchatka', 'Marshall Is.', 'Wellington', "Nuku'alofa"]
        #,13 => ["Nuku'alofa"] #move to top
      }
    end
      
end
