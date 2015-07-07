class ReceiversController < ApplicationController
  def ses_sns
    request_body = JSON.parse(request.body.read) rescue {}
    
    if request_body["SubscribeURL"] # access resque web to confirm SNS topic *manually*
      Resque.enqueue_to("crm_ses_confirm", "SubscribeURL", request_body["SubscribeURL"])
      
    else
      Resque.enqueue(SesReceiver, "sns", {:request_time => Time.now.to_i, :params => params, :request_body => request_body })
      
    end
    
    render :text => "ok"
  end
end
