class Unit < ActiveRecord::Base

  belongs_to :property
  
  validates :property_id, :bed, :bath, :sq_ft, :status, :rental_type, :presence => true
  validates :code, :uniqueness => {:scope => [:property_id] }
  
  default_scope { where(:deleted_at => nil).order("created_at desc") }
end