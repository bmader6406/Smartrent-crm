class UserDefinedAudience < Audience
  validates :name, :description, :presence => true
  
end
