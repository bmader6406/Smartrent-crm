class Region < ActiveRecord::Base
  
  
  has_many :properties, :class_name => "Property", :foreign_key => 'region_id'
  
  validates :name, :presence => true
  
  resourcify
end
