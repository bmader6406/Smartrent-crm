class NewsletterHylet < Hylet
  
  after_update :sync_audiences, :if => lambda { |h| !h.disable_audience_callback }
  after_update :sync_schedules, :if => lambda { |h| !h.disable_audience_callback }
  
  scope :nimda, -> { where(:property_id => nil, :campaign_id => nil) }
  
  attr_accessor :disable_audience_callback
  
  def subject
    "#{self[:title1]}"
  end
  
  def subject=(str)
    self[:title1] = str
  end
  
  def body_html
    self[:text1] || "Your HTML email goes here"
  end
    
  def body_html=(str)
    self[:text1] = str
  end
  
  def body_plain
    self[:text2] || "Your Plain text email goes here"
  end
  
  def body_plain=(str)
    self[:text2] = str
  end
  
  def raw_html?
    self[:title2] == "raw_html"
  end
  
  def audiences
    Audience.where(:id => audience_ids).includes(:property, :campaign)
  end
  
  #custom field
  
  def email_project
    @email_project ||= JSON.parse(self[:text3]) rescue {}
  end

  def email_project_was
    @email_project_was ||= JSON.parse(text3_was) rescue {}
  end
  
  def email_project=(lp)
    email_project if !@email_project
    @email_project = @email_project.merge(lp)
    self[:text3] = @email_project.to_json
  end
  
  def audience_ids
    email_project["audience_ids"].blank? ? [] : email_project["audience_ids"].collect{|aid| aid if aid.to_i > 0}.compact
  end
  
  def from
    email_project["from"].blank? ? "" : email_project["from"]
  end
  
  def reply_to
    email_project["reply_to"].blank? ? "" : email_project["reply_to"]
  end
  
  def cc
    email_project["cc"].blank? ? "" : email_project["cc"]
  end

  def bcc
    email_project["bcc"].blank? ? "" : email_project["bcc"]
  end

  def attachments
    email_project["attachments"].blank? ? "" : email_project["attachments"]
  end
  
  def body_text #for crm email editor, this will replace the {%body_text%} macro in the body_html
    email_project["body_text"].blank? ? "" : email_project["body_text"]
  end
  
  # for crm
  def audience_name
    @audience_name ||= audiences.collect{|a| a.name }
  end
  
  def set_audience_name(name)
    @audience_name = name
  end
  
  #[{:timestamp => timestamp, :action_id => aid, :is_send => false/true, :subject => {cid1 => ABC, cid2 => XYZ}}]
  # don't change to email_project["schedules"], because of the cache, it will not work correctly
  # !!! immediate send's schedules is EMPTY
  def schedules
    (JSON.parse(self[:text3])["schedules"] rescue []) || []
  end
  
  def tracking_urls #convert link of email to trackable link
    @tracking_urls ||= begin
      dict = {}

      self[:text1].scan(/href=["'\"\']http\S*["'\"\']/).collect{|url| url if !url.include?(HOST) }.compact.each do |url|
        url = url.gsub(/href=|"|'|\"|\'/, '')
        next if campaign.ad_domains.any? {|d| url.include?(d) }
        dict[url] = generate_tracking_url(url)
      end if self[:text1]
    
      self[:text2].scan(/http\S*/).collect{|url| url if !url.include?(HOST) }.compact.each do |url|
        next if campaign.ad_domains.any? {|d| url.include?(d) }
        dict[url] = generate_tracking_url(url)
      end if self[:text2]
    
      dict
    end
  end
  
  def header_macro
    @header_macro ||= begin
      arr = []
      [subject, from, reply_to, cc, bcc, attachments].each do |var|
        next if !var
        var.scan(/\{%[\w,@,.]*%\}/).each do |macro|
          arr << macro.gsub(/\{%|%\}/, '')
        end
      end
      
      arr.compact.uniq
    end
  end
  
  def body_macro
    @body_macro ||= begin
      arr = []
      [self[:text1], self[:text2]].each do |var|
        next if !var
        var.scan(/\{%[\w,@,.]*%\}/).each do |macro|
          arr << macro.gsub(/\{%|%\}/, '')
        end
      end
      
      arr.compact.uniq
    end
  end
  
  def refresh(premailer)
    self.disable_audience_callback = true
    
    if premailer.kind_of?(Premailer)
      if campaign.responsive?
        self.body_html = premailer.to_inline_css.gsub("</head>", "#{campaign.theme.css(campaign.theme_project, {:nlt_mb => 1 })} </head>")
      else
        self.body_html = premailer.to_inline_css
      end
      
    else #string
      self.body_html = premailer
    end
    
    self.save
  end
    
  private
    
    def generate_tracking_url(origin_url)
      #unescape the escaped html entities to have only unescaped url
      origin_url = CGI.unescapeHTML(origin_url)
      
      url = Url.find_or_initialize_by(campaign_id: campaign_id, origin_url: origin_url)
      url.save if url.new_record?
      url.to_tracking_url
    end
    
    def sync_audiences
      #p ">>> sync_audiences ", email_project_was["audience_ids"], email_project["audience_ids"]
      
      if email_project_was["audience_ids"] != email_project["audience_ids"]
        campaign.variates.each do |v|
          if v.variate_campaign.id != campaign_id && v.variate_campaign.newsletter_hylet
            v.variate_campaign.newsletter_hylet.update_attributes({
              :disable_audience_callback => true,
              :email_project => {"audience_ids" => audience_ids}
            })
          end
        end
        
      end #end if audience changed
    end
    
    def sync_schedules
      #p ">>> sync_schedules ", email_project_was["schedules"], schedules
      
      if email_project_was["schedules"] != schedules
        if campaign.kind_of?(NewsletterCampaign)
          campaign.variates.each do |v|
            if v.variate_campaign.id != campaign_id && v.variate_campaign.newsletter_hylet
              v.variate_campaign.newsletter_hylet.update_attributes({
                :disable_audience_callback => true,
                :email_project => {"schedules" => schedules}
              })
            end
          end
          
        end #end if type
        
      end #end if schedules changed
    end
    
end
