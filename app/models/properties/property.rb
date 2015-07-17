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
########################## SmartRent Property Associations #######################
  validates_uniqueness_of :name, :case_sensitive => true, :allow_blank => true
  has_attached_file :image, :styles => {:search_page => "150x150>"}, :path => ":rails_root/public/paperclip/:attachment/:id/:style/:filename", :url => "/paperclip/:attachment/:id/:style/:filename"
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
##################################################################################

  resourcify

  def setting
    @setting ||= begin
      property_setting ? property_setting : create_property_setting(:notification_emails => [user.email])
    end
  end

  def index_url
    "http://#{HOST}/properties/#{id}"
  end

  def to_macro(macro)
    attributes.keys.each do |k|
      macro["property.#{k}"] = self[k]
      macro["property.#{k}"] = "http://#{self[k]}" if !self[k].to_s.match(/^https?:\/\//i)
    end
  end
  
  
  # use persona.residents.with(:consistency => :strong) to switch to primary for action that requires no lag
  #   such as: showing entry after submit, check if resident have been imported or not

  # for mongoid, no need to cache the query result because, it does not query the db if call .where only
  def residents
    Resident.with(:consistency => :eventual).where(:deleted_at => nil)
  end

#*****************************************SmartRent methods**************************
  def self.custom_ransack(q)
    Smartrent::Property.ransack(q)
  end 
  
end
