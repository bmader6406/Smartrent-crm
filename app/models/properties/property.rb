class Property < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :region
  
  has_one :property_setting
  
  has_many :tickets
  has_many :categories
  
  has_many :units
  has_many :notifications
  has_many :import_alerts
  has_many :assets
  
  has_many :campaigns
  has_many :audiences, :class_name => "Audience"
  
  validates :name, :presence => true, :uniqueness => {:scope => :deleted_at}

  has_attached_file :image, 
    :styles => {:search_page => "150x150>"},
    :storage => :s3,
    :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
    :path => ":class/:attachment/:id/:style/:filename"
  
  validates_attachment :image,
     :size => {:less_than => 10.megabytes, :message => "file size must be less than 10 megabytes" },
     :content_type => {
       :content_type => ['image/pjpeg', 'image/jpeg', 'image/png', 'image/x-png', 'image/gif'],
       :message => "must be either a JPEG, PNG or GIF image"
      }
  
  default_scope { where(:deleted_at => nil) }
       
  scope :crm, -> { where(is_crm:  true) }
  scope :smartrent, -> { where(is_smartrent:  true) }
  
  resourcify

  def setting
    @setting ||= begin
      property_setting ? property_setting : create_property_setting(:notification_emails => user ? [user.email] : [])
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

  # don't remove
  def self.custom_ransack(q)
    Smartrent::Property.ransack(q)
  end

  def formatted_website_url
    if website_url =~ /\A#{URI::regexp(['http', 'https'])}\z/
      website_url
    else
      "http://" + website_url
    end
  end
  
end
