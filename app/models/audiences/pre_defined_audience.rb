class PreDefinedAudience < Audience
  
  before_create :set_name #for audience query, sorting
  
  def all_resident?
    lead_type == "all_resident"
  end
  
  def current_resident?
    lead_type == "current_resident"
  end
  
  def future_resident?
    lead_type == "future_resident"
  end
  
  def past_resident?
    lead_type == "past_resident"
  end
  
  def notice_resident?
    lead_type == "notice_resident"
  end
  
  def na_resident?
    lead_type == "n/a_resident"
  end
  
  ###
  
  def name
    !self["name"].blank? ? self["name"] : default_name
  end
  
  def default_name
    if all_resident?
      "Residents - All"
      
    elsif current_resident?
      "Residents - Current"
    
    elsif future_resident?
      "Residents - Future"  
  
    elsif past_resident?
      "Residents - Past"
  
    elsif notice_resident?
      "Residents - Notice"
  
    elsif na_resident?
      "Residents - N/A"
    end
  end
  
  def description
    
    org_name = property ? "Property" : "Bozzuto"
    if all_resident?
      "All Residents of the #{property.name} #{org_name}"
        
    elsif current_resident?
      "Current Residents of the #{property.name} #{org_name}"
      
    elsif future_resident?
      "Future Residents of the #{property.name} #{org_name}"
      
    elsif past_resident?
      "Past Residents of the #{property.name} #{org_name}"
      
    elsif notice_resident?
      "Notice Residents of the #{property.name} #{org_name}"
      
    elsif na_resident?
      "N/A Residents of the #{property.name} #{org_name}"
    end
  end
  
  def pretty_expression
    if all_resident?
      "( Resident Status <b>IN</b> Current, Past, Future, Notice <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
        
    elsif current_resident?
      "( Resident Status <b>IS</b> Current <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
      
    elsif future_resident?
      "( Resident Status <b>IS</b> Future <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
      
    elsif past_resident?
      "( Resident Status <b>IS</b> Past <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
      
    elsif notice_resident?
      "( Resident Status <b>IS</b> Notice <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
      
    elsif na_resident?
      "( Resident Status <b>IS</b> N/A <b>AND</b> Subscriber Status <b>IS</b> Subscribed )"
    end
  end
  
  private
  
    def set_name
      self.name = default_name
    end
  
end
