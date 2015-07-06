class BlacklistedEvent < MailEvent
    
  def self.attr_count
    :blacklisted_count
  end
      
end
