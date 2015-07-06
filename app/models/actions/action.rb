class Action < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :actor, :class_name => "Property"
  belongs_to :subject, :polymorphic => true

end
