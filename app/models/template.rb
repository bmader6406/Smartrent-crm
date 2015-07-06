class Template < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :campaign
  
  validates :name, :category, :presence => true
  
  default_scope { order("name ASC") }
  
  scope :approved, -> { where(:approved => true, :deleted_at => nil, :property_id => nil) }
  scope :pending, -> { where(:approved => false, :deleted_at => nil, :property_id => nil) }
  
  scope :for_property, ->(property) { where(:property_id => property.id, :deleted_at => nil) }

  def status
    approved? ? "APPROVED" : "PENDING"
  end
  
  def self.categories(add = nil)
    ["email_newsletter"]
  end
  
  #==========
  
  def self.first
    Template.unscoped.where('approved = 1').order('id asc').first
  end
  
  def duplicate
    #create template

    template_campaign = campaign.duplicate
    template_campaign.property_id = nil
    template_campaign.save(:validate => false)

    template = Template.new(:campaign => template_campaign,  :name => "Unamed", :category => category)
    template.save(:validate => false)

    return template
  end

  private
    
end
