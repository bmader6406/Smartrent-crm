class Campaign < ActiveRecord::Base  

  # =================
  # = relationships =
  # =================
  
  belongs_to :property
  belongs_to :user
  
  belongs_to :parent, :class_name => "Campaign", :foreign_key => 'parent_id'
  belongs_to :root, :class_name => "Campaign", :foreign_key => 'root_id'
  
  has_many :hylets, -> { where("hylets.type IS NOT NULL") }, :dependent => :destroy, :foreign_key => "campaign_id"

  has_many :variation_metrics, :dependent => :destroy, :foreign_key => "campaign_id", :class_name => "VariationMetric"
  
  accepts_nested_attributes_for :hylets, :allow_destroy => true

  attr_accessor :duplicating, :template_class, :tmp_timestamp, :tmp_property_id
  
  # =================
  # = methods =
  # =================

  default_scope { order('campaigns.created_at DESC') }
  
  scope :for_property, ->(property) { where("property_id = #{property.id} AND root_id IS NULL AND parent_id IS NULL AND 
   type NOT IN ('TemplateCampaign', 'NewsletterRescheduleCampaign') AND deleted_at IS NULL") }

  def property_setting
    property.setting
  end
  
  def variates
    @variates ||= begin
      CampaignVariation.where(:campaign_id => to_root_id).includes(:variate_campaign)
    end
  end
  
  def set_variates(vs) #set from left-nav
    @variates = vs if !@variates && vs
  end
  
  def email_variates
    @email_variates ||= variates.collect{|v| v if v.class.to_s == "NewsletterCampaignVariation"}.compact
  end
  
  #====
  
  def variate
    @variate ||= variates.where(:variate_campaign_id => to_param.to_i).first
  end
  
  def channel_variates
    @channel_variates ||= begin
      if variate
        variates.where(:type => variate["type"], :channel => 0)
      else
        variates.where(:type => "NewsletterCampaignVariation")
      end
    end
  end
  
  #show random variate of a channel! Don't cache it
  def channel_random_variate
    vs = channel_variates.all
    control = vs[0]
    variant = vs[1]
    
    if variant #random
      rand(100) <= control.weight_percent ? control : variant
    elsif control
      control
    end
  end
  
  #dry channel, variant name
  def dict_variates
    @dict_variates ||= begin
      version = ["Control", "Variant"]
      all = []
      dict = {}
      
      CHANNELS.each do |channel|
        vs = self.send("#{channel}_variates").group_by {|v| v.channel }
        
        dict[channel] = vs.keys.sort{|a, b| a <=> b }.collect{|chn| vs[chn] }.each_with_index{|arr, i| 
          arr.each_with_index{|v, j| 
            order = vs.keys.length > 1 ? ".#{i+1}" : ""
            
            if self.kind_of?(NewsletterCampaign)
              channel_text = "Email"
              
            else
              channel_text = channel.titleize
            end
            
            v.channel_name = !v['channel_name'].blank? ? v['channel_name'] : "#{channel_text}#{order}"
            v.version = !v['version'].blank? ? v['version'] : version[j]
            
            v.name = "#{v.channel_name}: #{v.version}"
            v.index = j

            all << v
          }
        }
      end
      
      dict["all"] = all
      dict
    end
  end
  
  #variates || multi sends variantes
  def all_variates
    if nlt_clzz?
      multi_sends.collect{|c| c.variates }.flatten
    else
      variates
    end
  end
  
  def channel
    case self["type"]        
      when "NewsletterCampaign"
        "email"
    end
  end
  
  def variation_id
    @variation_id ||= variates.detect{|v| v.variate_campaign_id == self.id }.id rescue nil
  end
  
  #=========
  
  def live?
    self["parent_id"].blank?
  end
  
  def root?
    self["root_id"].blank?
  end
  
  def archived?
    !self["deleted_at"].blank?
  end
  
  def to_root
    @to_root ||= root? ? self : self.root
  end
  
  def to_root_id #don't define root_id
    self["root_id"] || self["id"]
  end
  
  def to_reschedule_id
    self["id"]
  end
  
  def published?
    is_published?
  end

  def to_param
    self["parent_id"].blank? ? self["id"].to_s : self["parent_id"].to_s
  end

  def annotation(full = false)
    !self['annotation'].blank? ? self['annotation'] : (self.root || self)["annotation"]
  end
  
  # =================
  # = for mailer =
  # =================
  
  def email_domain
    @email_domain ||= HOST # or make it configurable in property.setting
  end
  
  def ad_domains
    @ad_domains ||= []
  end
  
  def notification_emails
    property.setting ? property.setting.notification_emails : [user.email]
  end
  
  def newsletter_hylet
    @newsletter_hylet ||= hylets.detect{|h| h["type"] == 'NewsletterHylet' }
  end
  
  def set_newsletter_hylet(hylet) #for crm caching
    @newsletter_hylet = hylet
  end
  
  # =================
  # = methods =
  # =================
  
  #=====
  
  def duplicate #duplicate the current campaign, only use to create template campaign
    self.template_class = TemplateCampaign
    duplicate_data(clone_attrs(self), self)
  end
  
  def clone_attrs(obj)
    attrs = obj.attributes.clone

    attrs.delete("id");
    attrs.delete("type");
    attrs.delete("parent_id");
    attrs.delete("root_id");
    attrs.delete("published_at");
    attrs.delete("is_published");
    attrs.delete("annotation");
    attrs.delete("created_at");
    attrs.delete("updated_at");
    
    attrs.delete("sends_count")
    attrs.delete("variant_sends_count")
    attrs.delete("opens_count")
    attrs.delete("variant_opens_count")
    attrs.delete("unique_opens_count")
    attrs.delete("variant_unique_opens_count")
    
    attrs.delete("clicks_count")
    attrs.delete("variant_clicks_count")
    attrs.delete("unique_clicks_count")
    attrs.delete("variant_unique_clicks_count")
    
    attrs.delete("unsubscribes_count")
    attrs.delete("variant_unsubscribes_count")
    attrs.delete("blacklisted_count")
    attrs.delete("variant_blacklisted_count")
    attrs.delete("complaints_count")
    attrs.delete("variant_complaints_count")
    attrs.delete("bounces_count")
    attrs.delete("variant_bounces_count")
    
    attrs
  end
  
  def duplicate_data(attrs, source_campaign, create_variate = false , set_publish = false)

    # create new campaign from source campaign
    # then create new hylet, new form
    attrs["annotation"] = "#{source_campaign.annotation} (Copied)" if attrs["root_id"].blank?
    attrs["duplicating"] = true

    if set_publish && source_campaign.published_at
      attrs["is_published"] = source_campaign.is_published
      attrs["published_at"] = source_campaign.published_at
      attrs["state"] = source_campaign.state
    end

    campaign = (source_campaign.template_class || source_campaign.class).create(attrs)

    campaign.channel_variates.create(:variate_campaign_id => campaign.id, :channel => source_campaign.variate.channel) if create_variate

    source_campaign.hylets.each do |h|
      h2 = h.dup
      h2.campaign_id = campaign.id
      h2.save!
      
    end
    
    return campaign
    
  end
  
  def dashboard_url
    "http://#{HOST}/properties/#{property_id}/notices/#{to_root_id}"
  end
  
  #summary report
  # {"id" => 123, "property_id" => 456, "name" => "XYZ", "count" => 555}
  # name is used if audience is deleted
  # we update this cache fields after the newsletter is sent out
  def audience_counts
    @audience_counts ||= JSON.parse(self[:audience_counts]) rescue []
  end
  
  def audience_counts=(ac)
    self[:audience_counts] = ac.to_json
  end
  
  #total sends of the multi-send newsletter
  def nlt_clzz?
    self.class.to_s == "NewsletterCampaign"
  end
  
  def sent_ts
    tmp_timestamp.to_i
  end
  
  #root sends
  def multi_sends
    @multi_sends ||= begin
      if nlt_clzz?
        [self, NewsletterRescheduleCampaign.where(:group_id => id, :root_id => nil).all].flatten.collect{|c|
          c if sent_ts == 0 || sent_ts > 0 && c.published_at.to_i == sent_ts
        }.compact
      else
        [self]
      end
    end
  end
  
  def variant_sends
    @variant_sends ||= begin
      if nlt_clzz?
        [self, NewsletterRescheduleCampaign.where({:group_id => root_id, :parent_id => id}).all].flatten.collect{|c|
          c if sent_ts == 0 || sent_ts > 0 && c.published_at.to_i == sent_ts || c.class.to_s == "NewsletterCampaign" && c.to_root.published_at.to_i == sent_ts
        }.compact
      else
        [self]
      end
    end
  end
  
  ###
  
  def first_nlt_hylet
    @first_nlt_hylet ||= channel_variates.first.variate_campaign.newsletter_hylet
  end
  
  def sent_at
    if sent_ts == 0
      ts = first_nlt_hylet.schedules.collect{|s| Time.zone.at(s["timestamp"].to_i).to_s(:friendly_time) if s["is_send"]}.compact.join(", ")
      ts.blank? ? (published_at ? published_at.to_s(:friendly_time) : "Not Sent Yet") : ts
    else
      schedule = first_nlt_hylet.schedules.detect{|s| s["timestamp"].to_i == sent_ts && s["is_send"]}
      schedule ? Time.zone.at(sent_ts).to_s(:friendly_time) : "Not Sent Yet"
    end
  end
  
  private
  
    def create_hylets
      CampaignLibrary.create_default_hylets(self)
    end
    
end
