class Unit < ActiveRecord::Base

  belongs_to :property
  
  validates :property_id, :bed, :bath, :sq_ft, :status, :rental_type, :presence => true
  #validates :code, :uniqueness => {:scope => [:property_id] }, :allow_nil => true
  
  default_scope { where(:deleted_at => nil).order("created_at desc") }
  def self.keyed_by_code
    units = {}
    all.each do |unit|
      units[unit.code] = unit
    end
    units
  end
end
