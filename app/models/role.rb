# User has one role per resource
# there is no role with global resource

class Role < ActiveRecord::Base
  
  
  has_and_belongs_to_many :users, :join_table => :users_roles
  belongs_to :resource, :polymorphic => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify
  
  LIST = ["admin", "regional_manager", "property_manager", "marketing_coordinator"]
  
  DICT = {
    "admin" => "Corporate Administrator",
    "regional_manager" => "Regional Manager & SVP",
    "property_manager" => "Property Manager",
    "marketing_coordinator" => "Marketing Co-ordinator"
  }
  
  def pretty_name
    DICT[name]
  end
  
end