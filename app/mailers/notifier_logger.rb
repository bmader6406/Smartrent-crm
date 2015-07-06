# This queue will be queued by the BatchEnqueuer

class NotifierLogger
  
  def self.queue
    :crm_logger_batch
  end
  
  def self.perform(action, params)
    # params type is
    # - hash: update_counters 
    
    if action == "update_counters"
      metric = SendMailMetric.today
      metric[params["from"]] += params["count"] if metric[params["from"]]
      metric.save
    end
    
  end
  
end
