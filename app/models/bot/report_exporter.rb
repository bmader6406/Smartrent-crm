require 'csv'

class ReportExporter
  extend Resque::Plugins::Retry
  @retry_limit = RETRY_LIMIT
  @retry_delay = RETRY_DELAY
  
  def self.queue
    :crm_immediate
  end
  
  def self.init(page, campaign, params, start_at = nil, end_at = nil)
    @property = page
    @campaign = campaign
    @params = params
    
    if @params["range"] && @params["range"].last
      @start_at = @params["range"].first.to_time.in_time_zone.beginning_of_day + UtcOffset::DST_HOUR
      @end_at = @params["range"].last.to_time.in_time_zone.end_of_day + UtcOffset::DST_HOUR
    end
    
    Time.zone = page.setting.time_zone if page
    
    return self
  end
  
  def self.sendible?
    true
  end
  
  def self.conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
  end
  
  def self.channel_condition(id)
    if @params["channel"] == "all"
      "#{id} IN (#{@campaign.all_variates.collect{|v| v.id}.join(', ')}) AND"
    else
      "#{id} IN (#{@campaign.all_variates.collect{|v| v.id if v.channel == @params["channel"].to_i }.compact.join(', ')}) AND"
    end
  end
  
  def self.variation_metrics
    if @campaign.kind_of?(NewsletterCampaign)
      if @campaign.nlt_clzz?
        VariationMetric.where(:property_id => @campaign.property.id).where("#{channel_condition('variation_id').gsub('AND', '')}")
        
      else
        @campaign.variation_metrics.where("#{channel_condition('variation_id').gsub('AND', '')}")
      end
    end
  end
    
end
