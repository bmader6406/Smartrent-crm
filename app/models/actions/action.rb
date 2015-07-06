class Action < ActiveRecord::Base
  include MultiTenant::RandomPrimaryKeyHelper
  
  belongs_to :user
  belongs_to :actor, :class_name => "Property"
  belongs_to :subject, :polymorphic => true

end
