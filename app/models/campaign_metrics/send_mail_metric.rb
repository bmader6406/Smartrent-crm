class SendMailMetric < ActiveRecord::Base
  
  default_scope :order => 'created_at DESC'
  
  def self.today
    now = Time.now.utc
    metric = SendMailMetric.where("created_at #{(now.beginning_of_day..now.end_of_day).to_s(:db)}").first
    metric = SendMailMetric.new unless metric
    metric
  end
  
  def total
    self['alerts'] + self['renewals'] + self['reports'] + self['reports2'] + self['help'] + self['notifications']
  end
  
end
