class ResidentMetric < ActiveRecord::Base

  self.inheritance_column = :_type_disabled
  
  belongs_to :property
  
  validates :property_id, :type, :presence => true
end