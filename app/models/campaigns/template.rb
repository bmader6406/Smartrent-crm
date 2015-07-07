class Template < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :campaign
  belongs_to :property
  
  validates :name, :presence => true
  
  default_scope { where('templates.deleted_at IS NULL').order("templates.name ASC") }

  def self.first
    Template.unscoped.where('deleted_at IS NULL').order('id asc').first
  end
  
  def duplicate
    #create template

    template_campaign = campaign.duplicate
    template_campaign.property_id = nil
    template_campaign.save(:validate => false)

    template = Template.new(:campaign => template_campaign,  :name => "Unamed")
    template.save(:validate => false)

    return template
  end

  private
    
end
