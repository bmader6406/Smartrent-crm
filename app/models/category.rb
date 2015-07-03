class Category < ActiveRecord::Base

  has_many :tickets
  
  scope :active, -> { where(active:  true) }
  scope :inactive, -> { where(active: false) }
end