# Is used for reporting, Emails Sent
# The actual variant share the newsletter hylet with this campaign type
# This campaign type only created on the reschedule send

# belongs to newsletter campaign via group_id
# has root and children

class NewsletterRescheduleCampaign < NewsletterCampaign
  
  skip_callback :create, :after, :create_hylets
  
  def newsletter_hylet
    @newsletter_hylet ||= parent.newsletter_hylet
  end
  
  def to_reschedule_id
    self["parent_id"]
  end
  
  def to_parent #for entry activities
    @to_parent ||= parent ? parent : (self["group_id"] ? Campaign.find_by_id(self["group_id"]) : nil)
  end
  
end