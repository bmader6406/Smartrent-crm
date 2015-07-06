class UniqueLinkClickEvent < MailEvent
  
  validates :resident_id, :uniqueness => {:scope => [:campaign_id]}
  
  def self.attr_count
    :unique_clicks_count
  end
  
end
