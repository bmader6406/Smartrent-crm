class Audience < ActiveRecord::Base

  belongs_to :property
  belongs_to :campaign
  
  validates :property_id, :presence => true
  
  default_scope { order('created_at DESC') }
  
  #### unique leads count
  
  def self.unique_residents_count(query)
    #pp ">> unique_residents_count", query
    Resident.with(:consistency => :eventual).collection.aggregate([
       { "$match" => query},
       { "$group" => { :_id => "$_id" } },
       { "$group" => { :_id => 1, :count => { "$sum" => 1 } } }
    ])[0]["count"] rescue 0
  end
  
  def self.unique_residents_listing(query, limit, skip)
    #pp ">> unique_residents_listing, limit #{limit}, skip #{skip}", query
    Resident.with(:consistency => :eventual).collection.aggregate([
       { "$match" => query},
       { "$group" => { :_id => "$_id" } },
       { "$sort" => { "_id" => 1 } },
       { "$limit" => limit },
       { "$skip" => skip }
    ])
  end
  
  ####
  
  def expression
    @expression ||= parse_expression
  end
  
  def long_name
    if property
      "#{property.name} #{name}"
    else
      name
    end
  end
  
  def group_type
    if ["all_resident", "current_resident", "future_resident", "past_resident", "notice_resident", "n/a_resident"].include?(lead_type)
      "residents"
    else
      "user_defined"
    end
  end
  
  def expression=(exp)
    self[:expression] = exp
  end
  
  def parse_expression
    begin
      JSON.parse(self[:expression])
    rescue
      {}
    end
  end
  
  def residents
    @residents ||= begin
      
      property_hint = {"units.property_id" => 1 }
      
      if self.kind_of?(PreDefinedAudience)
        if all_resident?
          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            "status"  => {'$in' => ['Current', 'Past', 'Future', 'Notice']}, "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
      
        
        elsif current_resident?
          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            "status" => "Current", "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
            
        elsif future_resident?
          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            "status" => "Future", "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
              
        elsif past_resident?
          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            "status" => "Past", "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
          
        elsif notice_resident?
          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            "status" => "Notice", "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
            
        elsif na_resident?

          property.residents.where("units" => {'$elemMatch' => {"property_id" => property_id.to_s, 
            'status' => {'$in' => ['N/A', '', nil]}, "subscribed" => true }} ).extras(:hint => { "units.property_id" => 1, "units.status" => 1 })
        end
      end
      
    end
  end
  
  def residents_count
    @residents_count ||= residents.count
  end
  
end
