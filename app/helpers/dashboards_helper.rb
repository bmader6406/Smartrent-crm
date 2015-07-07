module DashboardsHelper
  def property_units
    @property.units.collect{|c| {:val => c.id.to_s, :label => c.code} }
  end
  
  def property_audiences
    audiences = @property.audiences.all
    
    if audiences.empty?
      audiences = [] #reset
      
      ["all_resident", "current_resident", "future_resident", "past_resident", "notice_resident", "n/a_resident"].each do |type|
        audiences << PreDefinedAudience.create!(:property_id => @property.id, :lead_type => type)
      end
    end
    
    audiences.collect{|c| {:val => c.id.to_s, :label => c.name} }.compact
  end
  
end