class Event < ActiveRecord::Base
  
  belongs_to :property
  belongs_to :campaign
  
  has_one :url, :primary_key => "url_id", :foreign_key => "id"
  
  attr_accessor :bounce_type
  
end
