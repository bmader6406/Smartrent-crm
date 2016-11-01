class Campaign < ActiveRecord::Base  

  belongs_to :property
  belongs_to :user
  
  attr_accessor :tmp_property_id
  
  default_scope { order('campaigns.created_at DESC') }
  
  scope :for_property, ->(property) { where("property_id = #{property.id} AND type NOT IN ('TemplateCampaign') AND deleted_at IS NULL") }
  
  serialize :audience_ids, Array
  serialize :audience_counts, JSON
  

  def property_setting
    property.setting
  end
  
  def audiences
    Audience.where(:id => audience_ids).includes(:property, :campaign)
  end
  
  def audience_name
    @audience_name ||= audiences.collect{|a| a.name }
  end
  
  def set_audience_name(name)
    @audience_name = name
  end

  # =================
  # = for mailer =
  # =================
  
  def dashboard_url
    "https://#{HOST}/properties/#{property_id}/notices/#{id}"
  end
  
  def preview_url
    "https://#{HOST}/properties/#{property_id}/notices/#{id}/preview"
  end
  
  ###
  
  def sent_at
    published_at ? published_at.to_s(:friendly_time) : "Not Sent Yet"
  end
  
  def tracking_urls #convert link of email to trackable link
    @tracking_urls ||= begin
      dict = {}

      body_html.scan(/href=["'\"\']http\S*["'\"\']/).collect{|url| url if !url.include?(HOST) }.compact.each do |url|
        url = url.gsub(/href=|"|'|\"|\'/, '')
        dict[url] = generate_tracking_url(url)
      end if body_html
    
      body_plain.scan(/http\S*/).collect{|url| url if !url.include?(HOST) }.compact.each do |url|
        dict[url] = generate_tracking_url(url)
      end if body_plain
    
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
      [body_plain, body_html].each do |var|
        next if !var
        var.scan(/\{%[\w,@,.]*%\}/).each do |macro|
          arr << macro.gsub(/\{%|%\}/, '')
        end
      end
      
      arr.compact.uniq
    end
  end
    
  private
    
    def generate_tracking_url(origin_url)
      #unescape the escaped html entities to have only unescaped url
      origin_url = CGI.unescapeHTML(origin_url)
      
      url = Url.find_or_initialize_by(campaign_id: id, origin_url: origin_url)
      url.save if url.new_record?
      url.to_tracking_url
    end
    
end
