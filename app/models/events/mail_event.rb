class MailEvent < Event
  
  after_create :increase_counter_cache
  after_create :create_activity
  
  def resident
    @resident ||= Resident.with(:consistency => :eventual).where(:_id => resident_id).first
  end
  
  def eager_load(subject)
    @resident = subject
    self
  end
  
  private
    
    def increase_counter_cache
      Campaign.update_counters campaign_id, self.class.attr_count => 1
    end
    
    def create_activity
      
      case self['type']
        when "SendEvent"
          #this activity will be created by the campaign newsletter mailer
          
        when "OpenEvent"
          if resident
            resident.marketing_activities.create(:action => "open_mail", :subject_id => campaign.id, :subject_type => campaign.class.to_s, :created_at => created_at)
          end
          
        when "UniqueOpenEvent"
          if resident && campaign.kind_of?(NewsletterCampaign)
            open_mail = resident.marketing_activities.detect{|a| a.subject_id.to_i == campaign_id && a.action == "open_mail" }
            
            if open_mail
              prop = resident.properties.detect{|p| p.property_id.to_i == open_mail.property_id.to_i }
              
              if prop
                prop.opens_count += 1
                prop.finalize_score
              else
                resident.opens_count += 1
                resident.finalize_score
              end
            end
          end
          
        when "LinkClickEvent"
          if resident
            resident.marketing_activities.create(:action => "click_link", :subject_id => campaign.id, :subject_type => campaign.class.to_s,
              :target_id => url_id , :target_type => "Url", :created_at => created_at )
          end
          
        when "UniqueLinkClickEvent"
          if resident && campaign.kind_of?(NewsletterCampaign)
            click_link = resident.marketing_activities.detect{|a| a.subject_id.to_i == campaign_id && a.action == "click_link" }
            
            if click_link
              prop = resident.properties.detect{|p| p.property_id.to_i == click_link.property_id.to_i }
              
              if prop
                prop.clicks_count += 1
                prop.finalize_score
              else
                resident.clicks_count += 1
                resident.finalize_score
              end
            end
          end
          
        when "BlacklistedEvent"
          #this activity will be created by the campaign newsletter mailer
          
        when "BounceEvent"
          if resident
            resident.marketing_activities.create(:action => "bounce", :subject_id => campaign.id, :subject_type => campaign.class.to_s, :created_at => created_at)
            
            # mark email as bounce immediately for ALJ
            if ["1470172458182649674"].include?(resident.property_id) || bounce_type == "Permanent" || resident.bounces_count > 0 # two in a row
              resident.unsubscribe(campaign, "unsubscribe_bounce")
              resident.update_attributes(:email_check => "Bad", :bounces_count => resident.bounces_count + 1)
            else
              resident.update_attribute(:bounces_count, resident.bounces_count + 1)
            end
          end
          
        when "ComplaintEvent"
          if resident
            resident.marketing_activities.create(:action => "complain", :subject_id => campaign.id, :subject_type => campaign.class.to_s, :created_at => created_at)
            resident.unsubscribe(campaign, "unsubscribe_complaint")
          end
          
        when "UnsubscribeClickEvent"
          #this activity will be created by the the resident.subscribe/unsubscribe action
      end
    end

end
