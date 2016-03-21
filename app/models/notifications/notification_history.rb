class NotificationHistory < ActiveRecord::Base
  belongs_to :notification
  belongs_to :actor, :class_name => "User"
  
  validates :notification_id, :actor_id, :state, :presence => true
end
