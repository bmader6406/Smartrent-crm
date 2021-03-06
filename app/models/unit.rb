class Unit < ActiveRecord::Base

  belongs_to :property
  #has_many :residents
  
  validates :property_id, :bed, :bath, :sq_ft, :status, :rental_type, :presence => true
  #validates :code, :uniqueness => {:scope => [:property_id] }, :allow_nil => true
  
  default_scope { where(:deleted_at => nil) }
  
  def residents
    # must assign array manually, otherwise curr_unit will not work on rabl view
    primary_residents = []
    roommates = []
    
    Resident.ordered("first_name asc").where("units" => {
      "$elemMatch" => { 
        "property_id" => self.property.id.to_s, 
        "unit_id" => self.id.to_s,
        "status" => "Current"
      }
    }).each do |r|
      r.curr_unit_id = self.id.to_s
      
      next if !r.curr_unit
      
      if r.curr_unit.roommate?
        roommates << r
      else
        primary_residents << r
      end
    end
    
    primary_residents + roommates
  end

  def primary_resident
    Resident.ordered("first_name asc").where("units" => {
      "$elemMatch" => { 
        "property_id" => self.property.id.to_s, 
        "unit_id" => self.id.to_s,
        "status" => "Current"
      }
    }).collect { |r|
      r.curr_unit_id = self.id.to_s
      r.curr_unit && !r.curr_unit.roommate? ? r : nil
    }.compact.first
  end

end
