class UniqueOpenEvent < MailEvent
  
  after_create :update_send_event
  
  validates :resident_id, :uniqueness => {:scope => [:campaign_id]}
  
  def self.attr_count
    :unique_opens_count
  end
  
  private
  
    def update_send_event
      event = SendEvent.find_by(campaign_id: self.campaign_id, resident_id: self.resident_id)
      
      if event && !event.opened_at
        if event.created_at > created_at
          start_at = created_at
          end_at = event.created_at
        else
          start_at = event.created_at
          end_at = created_at
        end
        
        event.update_attributes(:opened_at => start_at, :response_time => end_at.to_i - start_at.to_i)
      end
    end
    
    
end
