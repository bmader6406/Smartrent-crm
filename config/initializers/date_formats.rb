require 'active_support/core_ext'

date_formats = {
  :short_date => lambda { |date| date.strftime("#{date.mon}/%d/%Y") },  # 1/23/2010
  :date_time => lambda { |date| date.strftime("#{date.mon}/%d %H:%M:%S") },  # 1/23 11:54:41
  :friendly_time => lambda { |date| date.strftime("%Y-%b-%d %l:%M %p") }, #2010-Otc-01 9:33 AM #http://apidock.com/ruby/Time/strftime
  :friendly_date => lambda { |date| date.strftime("%Y-%b-%d") }, #2010-Otc-01
  :nimda_time => lambda { |time| time.in_time_zone('Eastern Time (US & Canada)').strftime("%m/%d/%Y %H:%M") }, #mm/dd/yyyy hh:mm
  :nimda_date => lambda { |time| time.to_time.in_time_zone('Eastern Time (US & Canada)').strftime("%Y-%b-%d") }, #2010-Otc-01
  :schedule_time => lambda { |date| date.strftime("%m/%d/%Y %H:%M") },
  :schedule_time_with_zone => lambda { |date| date.strftime("%m/%d/%Y %H:%M  (%z %Z)") },  
  :timeline_date => lambda { |date| date.strftime("%b %d")},
  :sw_date =>  lambda { |date| date.strftime("%B %e, %Y")},
  :visit_time => lambda { |date| date.strftime("%H:%M:%S %b %d")}, #12:50:08 Sep 6
  :csv_time => lambda { |date| date.strftime("%Y-%m-%d %H:%M:%S")},
  :utc_date => lambda { |date| date.to_time.in_time_zone('UTC').strftime("%Y-%b-%d") } #2010-Otc-01
}

Time::DATE_FORMATS.merge!(date_formats)
Date::DATE_FORMATS.merge!(date_formats)

# make ruby 1.9 use American date
def Date.parse(value = nil)
  value = value.strip
  if value =~ /^(\d{1,2})\/(\d{1,2})\/(\d{2})$/
    ::Date.civil($3.to_i + 2000, $1.to_i, $2.to_i)
  elsif value =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/
    ::Date.civil($3.to_i, $1.to_i, $2.to_i)
  else
    ::Date.new(*::Date._parse(value, false).values_at(:year, :mon, :mday))
  end
end

