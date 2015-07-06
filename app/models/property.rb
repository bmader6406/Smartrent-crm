class Property < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :region
  
  has_one :property_setting
  
  has_many :tickets
  has_many :categories
  
  has_many :units
  has_many :notifications
  has_many :assets
  
  has_many :campaigns
  has_many :audiences, :class_name => "Audience"
  
  validates :name, :presence => true
  
  resourcify
  
  def setting
    @setting ||= begin
      property_setting ? property_setting : create_property_setting(:notification_emails => [user.email])
    end
  end
  
  # use persona.residents.with(:consistency => :strong) to switch to primary for action that requires no lag
  #   such as: showing entry after submit, check if entry have been imported or not

  # for mongoid, no need to cache the query result because, it does not query the db if call .where only
  def residents
    Resident.with(:consistency => :eventual).where(:deleted_at => nil)
  end
  
end
