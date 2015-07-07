class MonitorMetric < ActiveRecord::Base
  default_scope { order('created_at DESC') }
  
  serialize :bounces
  serialize :complaints
  serialize :error_details
  
end
