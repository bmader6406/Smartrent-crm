class Template < ActiveRecord::Base
  include MultiTenant::RandomPrimaryKeyHelper
  
  belongs_to :user
  belongs_to :campaign
  
  validates :name, :category, :presence => true, :if => lambda { |t| t.parent? }
  
  belongs_to :parent, :class_name => "Template", :foreign_key => 'parent_id'
  has_many :children, :class_name => "Template", :foreign_key => 'parent_id', :dependent => :destroy

  default_scope { order("name ASC") }
  
  scope(:approved, :conditions=>{:parent_id => nil, :approved => true, :deleted_at => nil, :property_id => nil})
  scope(:pending, :conditions=>{:parent_id => nil, :approved => false, :deleted_at => nil, :property_id => nil})
  
  scope(:for_property, lambda { |property|
    { :conditions=>{:property_id => property.id, :deleted_at => nil }}
  })

  def status
    approved? ? "APPROVED" : "PENDING"
  end
  
  def self.categories(add = nil)
    ["email_newsletter"]
  end
  
  def campaign_type
    "newsletter"
  end
  
  #==========
  
  def parent?
    self["parent_id"].blank?
  end
  
  def self.first
    Template.unscoped.where('parent_id IS NULL AND approved = 1').order('id asc').first
  end
  
  #===
  
  def campaign_clzz
    case channel
      when "email"
        NewsletterCampaign
    end
  end
  
  def duplicate
    lead_def = nil

    #create template

    template_campaign = campaign.duplicate
    template_campaign.property_id = nil
    template_campaign.save(:validate => false)

    if lead_def && template_campaign.form
      template_campaign.form.update_attribute(:lead_def_id, lead_def._id)
    end

    template = Template.new(:campaign => template_campaign,  :name => "Unamed", :category => category, :channel => channel)
    template.save(:validate => false)

    return template
  end

  private
    
end
