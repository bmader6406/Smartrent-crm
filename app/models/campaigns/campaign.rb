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

  attr_accessor :duplicating, :template_class, :tmp_timestamp
  
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
    @email_variates ||= variates.collect{|v| v if v.class.to_s == "LandingCampaignVariation"}.compact
  end
  
  #====
  
  def variate
    @variate ||= variates.where(:variate_campaign_id => to_param.to_i).first
  end
  
  def channel_variates
    @channel_variates ||= begin
      if variate
        variates.where(:type => variate["type"], :channel => variate.channel)
      else
        variates.where(:type => "LandingCampaignVariation")
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
      
      dict["email"] = dict["facebook"] #for newsletter      
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
  
  def variant_name
    v = dict_variates["all"].detect{|v| v.variate_campaign_id == to_param.to_i}
    v ? v.name : nil
  end
  
  def variant_url
    v = dict_variates["all"].detect{|v| v.variate_campaign_id == to_param.to_i}
    v ? "#{permanent_url(v.channel)}/#{v.index}" : nil
  end
  
  def variant_version
    v = dict_variates["all"].detect{|v| v.variate_campaign_id == to_param.to_i}
    v ? v.version : nil
  end

  def channel
    case self["type"]        
      when "NewsletterCampaign"
        "email"
    end
  end
  
  #========
  
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
    @annotation ||= begin
      if self["type"] == "NurtureCampaign"
        anno = !self['annotation'].blank? ? self['annotation'] : "Days: #{trigger_day}"
        full ? "#{drip.annotation} > #{anno}" : anno
      else
        !self['annotation'].blank? ? self['annotation'] : (self.root || self)["annotation"]
      end
    end
  end
  
  # =================
  # = for mailer =
  # =================
  
  def email_domain
    @email_domain ||= property_setting.email_domain.blank? ? HOST : property_setting.email_domain
  end
  
  def ad_domains
    @ad_domains ||= property.to_root.setting.ad_domains rescue []
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
  
  #reduce queries
  def variant_stats(variation_id, range = nil)
    @variant_conversion ||= begin
      dict = {}
      tz = property_setting.time_zone
      if range
        start_at = range.first.to_time.in_time_zone(tz).beginning_of_day + UtcOffset::DST_HOUR
        end_at = range.last.to_time.in_time_zone(tz).end_of_day + UtcOffset::DST_HOUR
      else
        Time.zone = tz
        start_at = (Time.zone.today - 30.day).beginning_of_day + UtcOffset::DST_HOUR
        end_at = (Time.zone.today - 1.day).end_of_day + UtcOffset::DST_HOUR
      end
      
      lead_metrics.where("variation_id IN (#{variates.collect{|v| v.id}.join(', ')}) AND created_at #{(start_at..end_at).to_s(:db)}").select("sum(residents_count) as residents_count,
            sum(sessions_count) as sessions_count, variation_id").group("variation_id").all.each do |lm|
            
        dict[lm.variation_id] = [lm.residents_count, lm.sessions_count] 
      end
      
      dict
    end

    @variant_conversion[variation_id] || [] #[] is used when no metric found
  end
  
  def thumbnails
    @thumbnails ||= begin
      dict = {}
      ThumbnailAsset.joins("inner join campaigns on campaigns.thumbnail_asset_id = assets.id").where("campaigns.id = #{to_root_id} OR campaigns.root_id = #{to_root_id}").each do |asset|
        dict[asset.id] = asset
      end
      dict
    end
  end
  
  def variation_id
    @variation_id ||= variates.detect{|v| v.variate_campaign_id == self.id }.id rescue nil
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
  
  def conversion(num, total)
    (total.to_i.zero? ? 0 : num.to_f*100/total.to_f).round(2)
  end
  
  def dashboard_url #
    "http://#{HOST}/landing/#{to_root_id}/dashboard"
  end
  
  def report_url
    "http://#{HOST}/landing/#{to_root_id}/reports"
  end
  
  def design_url
    "http://#{HOST}/landing/#{self['id']}/edit"
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
