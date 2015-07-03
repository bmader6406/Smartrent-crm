class Call < ActiveRecord::Base

  belongs_to :comment
  
  validates :comment_id, :from, :to, :presence => true
end