# this class is used to enqueue the job that can execute in batch
# such as responder mailer, campaign logger to improve the performance

# run every minute by the resque-scheduler
# auto enqueue itself if there are more jobs

# 1. jobs are enqueued to crm_job_buffer
# 2. crm_batch_builder read 1. to organize jobs to 3
# 3. >> crm_email_logger_batch

class BatchEnqueuer
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_immediate
  end
  
  def self.perform(name = "crm_job_buffer", count = 2000)
    ActiveRecord::Base.logger.level = 1
    pp "Enter BatchEnqueuer perform "

    
    #ConversationMonitor.perform #temp
    
    queue = "queue:#{name}"
    batch = {}

    pp  "queue:#{name}"

    count.times do |i|
      json_job = Resque.redis.lpop queue
      
      next if !json_job
      pp "json_job: #{json_job}"
      job = JSON.parse(json_job)
      
      pp "processing: #{i+1} - #{job["class"]}"
      
      if job["class"] == "CampaignLogger"
        pp "CampaignLogger"
        campaign_id, action, hash = job["args"]
        
        k = "CampaignLogger___#{campaign_id}___#{action}"
        
        if batch[k]
          batch[k] << hash

        else
          batch[k] = [hash]

        end
        
      else #push other jobs to a new queue
        
        new_name = "#{name}_2"
        Resque.enqueue_to(new_name, "init ui") if !Resque.redis.exists("queue:#{new_name}")
        pp "init" if !Resque.redis.exists("queue:#{new_name}")
        Resque.redis.rpush "#{queue}_2", json_job
      end
    end
    
    #enqueue in batches
    batch.keys.each do |k|
      if k.include?("CampaignLogger")
        pp "if key CampaignLogger"
        clzz, campaign_id, action = k.split("___")
        
        if ["track_open", "track_click"].include?(action)
          # create email stats asap
          Resque.enqueue_to(:crm_email_logger_batch, Kernel.const_get(clzz), campaign_id.to_i, action, batch[k])
        else

          Resque.enqueue(Kernel.const_get(clzz), campaign_id.to_i, action, batch[k])
        end
      end
    end
    
    Resque.enqueue(self, name, count) if Resque.redis.llen(queue) > 0    
  end
  
  def self.class_from_string(str)
    pp "class_from_string"
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
  
end
