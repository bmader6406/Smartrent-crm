class MarketingActivity
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :note, :type => String
  field :action, :type => String
  field :actor_id, :type => String
  field :actor_type, :type => String
  field :subject_id, :type => String
  field :subject_type, :type => String
  field :target_id, :type => String
  field :target_type, :type => String
  
  field :property_id, :type => String

  embedded_in :resident
  
  before_create :set_property_id, :if => lambda { |a| !a.unify_resident } # for activity filtering
  
  after_create :increase_counter_cache, :if => lambda { |a| !a.unify_resident }
  
  after_destroy :decrease_counter_cache
  
  attr_accessor :unify_resident
  
  # can be campaign
  def subject
    @subject ||= begin
      s = class_from_string(subject_type).find_by_id(subject_id) rescue nil
    end
  end
  
  # can be url (click), property (subscribe/unsubscribe)
  def target
    @target ||= target_id ? (class_from_string(target_type).find_by_id(target_id) rescue nil) : nil
  end
  
  def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
  
  def note
    !self[:note].blank? ? self[:note] : begin
      if subject
        case action
          when "import"
            "Imported"
            
          when "send_mail"
            "<b>Received</b> newsletter <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a>"

          when "open_mail"
            "<b>Opened</b> <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"

          when "click_link"
            "<b>Clicked</b> <a href='#{target.origin_url}' target='_blank'>#{target.origin_url}</a> link in the <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"

          when "bounce"
            "<a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter was bounced"

          when "blacklist"
            "<b>Blacklisted</b> <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"

          when "complain"
            "<b>Complained</b> <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"

          when "unsubscribe" #legacy
            "<b>Clicked</b> unsubscribe link in the <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            
          when "unsubscribe_confirm"
            if target && subject
              "<b>Unsubscribed</b> <a href='#{target.index_url}' target='_blank'>#{target.name}</a> from <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            elsif subject && subject.property
              "<b>Unsubscribed</b> <a href='#{subject.property.index_url}' target='_blank'>#{subject.property.name}</a> from <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            else
              "<b>Unsubscribed</b>"
            end
            
          when "unsubscribe_confirm_all"
            "<b>Unsubscribed</b> all sub-orgs from the <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            
          when "unsubscribe_blacklisted"
            "Auto-unsubscribe - Reason: Blacklisted <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            
          when "unsubscribe_bounce"
            "Auto-unsubscribe - Reason: <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter was bounced"
            
          when "unsubscribe_complaint"
            "Auto-unsubscribe - Reason: Complained <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"

          when "subscribe"
            if target && subject
              "<b>Resubscribed</b> <a href='#{target.index_url}' target='_blank'>#{target.name}</a> from <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            elsif subject && subject.property
              "<b>Resubscribed</b> <a href='#{subject.property.index_url}' target='_blank'>#{subject.property.name}</a> from <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
            else
              "Resubscribed"
            end
            
          when "subscribe_property"
            "<b>Resubscribed</b> <a href='#{target.index_url}' target='_blank'>#{target.name}</a> from <a href='#{subject.dashboard_url}' target='_blank'>#{subject.annotation(true)}</a> newsletter"
        end
        
      else
        
        case action
          when "bulk_unsubscribe"
            "Auto-unsubscribe - Reason: Bulk Unsubscribe"
            
          when "bulk_resubscribe"
            "Resubscribed - Reason: Bulk Resubscribe"
            
          when "bad_email_verified"
            "Auto-unsubscribe - Reason: Bad Email"
            
          when "bad_email_found"
            "Auto-unsubscribe - Reason: Bad Email"
            
          else
            action
        end
      end
      
    end
  end

  protected
  
    def increase_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"marketing_activities_count" => 1}}, {:multi => true})
    end

    def decrease_counter_cache
      Resident.collection.where({"_id" => resident._id}).update({'$inc' => {"marketing_activities_count" => -1}}, {:multi => true})
    end
    
    def set_property_id
      if subject
        if subject.kind_of?(Campaign)
          self.property_id = subject.property_id.to_s # default to property's campaign
          
          if !resident.properties.empty? # switch page
            prop = resident.properties.detect{|p| p.property_id.to_i == subject.property_id }
          
            if !prop # check cross send
              audience = resident.to_cross_audience(subject)

              if audience && audience.property_id
                prop = resident.properties.detect{|p| p.property_id.to_i == audience.property_id }
              end
            end
          
            self.property_id = prop.property_id if prop
          end
        end
        
      else
        self.property_id = resident.property_id # default to property's resident
      end
    end
    
end