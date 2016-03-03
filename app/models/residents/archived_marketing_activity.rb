class ArchivedMarketingActivity
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  
  include MultiTenant::RandomPrimaryKeyHelper

  field :_id, :type => String
  field :resident_id, :type => String

  index({ resident_id: 1, created_at: 1 })

  def to_attrs
    attrs = attributes
    attrs.delete(:resident_id)
    attrs.delete(:_id)
    attrs.delete(:_origin_id)
    attrs
  end

end