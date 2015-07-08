class Template < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :campaign
  belongs_to :property
  
  validates :name, :presence => true
  
  default_scope { where('templates.deleted_at IS NULL').order("templates.name ASC") }

  def self.first
    Template.unscoped.where('deleted_at IS NULL').order('id asc').first
  end
end
