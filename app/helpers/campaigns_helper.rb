module CampaignsHelper
  
  def send_filter_select(url)
    if @campaign.first_nlt_hylet.schedules.collect{|s| s if s["is_send"]}.compact.length > 1
      
      dd = "<div id='send-dropdown' class='dropdown dd-filter'><a href='#' class='dropdown-toggle' data-toggle='dropdown'> 
              Send Date: #{params[:timestamp].blank? ? "All Sends" : Time.zone.at(params[:timestamp].to_i).to_s(:friendly_time)} <i class='caret'> </i> </a>"
      dd << "<ul class='dropdown-menu'>"
    
      dd << "<li class='#{"active" if params[:timestamp].blank? }'><a href='#{url}'> All Sends </a></li>"

      @campaign.first_nlt_hylet.schedules.each do |schedule|
        # hide reschedule send if not sent yet
        next if !schedule["is_send"]
        
        dd << "<li class='#{"active" if params[:timestamp].to_i == schedule["timestamp"].to_i }'>
                <a href='#{url}?timestamp=#{schedule["timestamp"]}'> #{Time.zone.at(schedule["timestamp"].to_i).to_s(:friendly_time)} </a></li>"
      end
    
      dd << "</ul></div>"
    end
  end
  
end